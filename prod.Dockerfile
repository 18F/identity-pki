# this part builds everything
FROM ruby:3.3.4-slim-bullseye as builder

# Set environment variables
ENV RAILS_ROOT /app
ENV RAILS_ENV production
ENV BUNDLE_PATH /app/vendor/bundle
ENV NGINX_VERSION 1.22.0

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    gettext-base \
    git-core \
    tar \
    unzip \
    jq \
    libcurl4-openssl-dev \
    libjemalloc-dev \
    libpcre3 \
    libpcre3-dev \
    libssl-dev \
    libpq-dev \
    patch \
    python3 \
    python3-pip \
    python3-venv \
    util-linux \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Download RDS Combined CA Bundle
RUN mkdir -p /usr/local/share/aws \
  && curl https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem > /usr/local/share/aws/rds-combined-ca-bundle.pem \
  && chmod 644 /usr/local/share/aws/rds-combined-ca-bundle.pem

# Create working directory
WORKDIR $RAILS_ROOT

# do a bundle install
COPY .ruby-version $RAILS_ROOT/.ruby-version
COPY Gemfile $RAILS_ROOT/Gemfile
COPY Gemfile.lock $RAILS_ROOT/Gemfile.lock
RUN bundle config build.nokogiri --use-system-libraries
RUN bundle config set --local deployment 'true'
RUN bundle config set --local path $BUNDLE_PATH
RUN bundle config set --local without 'deploy development doc test'
RUN bundle install --jobs $(nproc)
RUN bundle binstubs --all



#####################################################
# here is where the actual image gets built
FROM ruby:3.3.4-slim-bullseye

SHELL ["/bin/bash", "-c"]

# Set environment variables
ENV RAILS_ROOT /app
ENV RAILS_ENV production
ENV BUNDLE_PATH /app/vendor/bundle

# Prevent documentation installation
RUN echo 'path-exclude=/usr/share/doc/*' > /etc/dpkg/dpkg.cfg.d/00_nodoc && \
    echo 'path-exclude=/usr/share/man/*' >> /etc/dpkg/dpkg.cfg.d/00_nodoc && \
    echo 'path-exclude=/usr/share/groff/*' >> /etc/dpkg/dpkg.cfg.d/00_nodoc && \
    echo 'path-exclude=/usr/share/info/*' >> /etc/dpkg/dpkg.cfg.d/00_nodoc && \
    echo 'path-exclude=/usr/share/lintian/*' >> /etc/dpkg/dpkg.cfg.d/00_nodoc && \
    echo 'path-exclude=/usr/share/linda/*' >> /etc/dpkg/dpkg.cfg.d/00_nodoc

# Setup timezone data
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install dependencies
RUN apt-get update && apt-get install -y \
    gettext-base \
    git-core \
    curl \
    libcurl4-openssl-dev \
    libjemalloc-dev \
    libpcre3 \
    libpcre3-dev \
    libssl-dev \
    libpq-dev \
    patch \
    util-linux \
    postgresql-contrib \
    && rm -rf /var/lib/apt/lists/*

# Create user and setup working directory
RUN addgroup --gid 1000 app && \
    adduser --uid 1000 --gid 1000 --disabled-password --gecos "" app && \
    mkdir -p $RAILS_ROOT && \
    mkdir -p $RAILS_ROOT/tmp/pids && \
    mkdir -p $RAILS_ROOT/log

# copy rds cert from builder
COPY --from=builder /usr/local/share/aws/rds-combined-ca-bundle.pem /usr/local/share/aws/rds-combined-ca-bundle.pem

# Copy bundle in
COPY --from=builder $RAILS_ROOT $RAILS_ROOT

COPY package.json $RAILS_ROOT/package.json

WORKDIR $RAILS_ROOT

# Copy Application Code
COPY ./lib ./lib
COPY ./app ./app
COPY ./config ./config
COPY ./config.ru ./config.ru
COPY ./db ./db
COPY ./bin ./bin
COPY ./public ./public
COPY ./spec ./spec
COPY ./vendor ./vendor
COPY ./Rakefile ./Rakefile
COPY ./Makefile ./Makefile
COPY ./Procfile ./Procfile
COPY ./log ./log
COPY ./tmp ./tmp
RUN mkdir -p ${RAILS_ROOT}/keys; chmod -R 0755 ${RAILS_ROOT}/keys; \
    mkdir -p ${RAILS_ROOT}/tmp/cache; chmod -R 0755 ${RAILS_ROOT}/tmp/cache; \
    mkdir -p ${RAILS_ROOT}/tmp/pids; chmod -R 0755 ${RAILS_ROOT}/tmp/pids; \
    mkdir -p ${RAILS_ROOT}/tmp/sockets; chmod -R 0755 ${RAILS_ROOT}/tmp/sockets; \
    mkdir -p ${RAILS_ROOT}/config/puma; chmod -R 0755 ${RAILS_ROOT}/config/puma; 
COPY --chmod=644 ./k8files/newrelic.yml ./config/newrelic.yml

# set bundler up
RUN bundle config set --local frozen 'true'
RUN bundle config set --local deployment 'true'
RUN bundle config set --local path $BUNDLE_PATH
RUN bundle config set --local without 'deploy development doc test'

# make everything the proper perms after everything is initialized
RUN chown -R app:app $RAILS_ROOT/tmp && \
    chown -R app:app $RAILS_ROOT/log && \
    find $RAILS_ROOT -type d | xargs chmod 755

# get rid of suid/sgid binaries
RUN find / -perm /4000 -type f | xargs chmod u-s
RUN find / -perm /2000 -type f | xargs chmod g-s

# Expose port the app runs on
EXPOSE 443

USER app

# The keys here are getting mapped in from a secret in the deployment.
CMD ["bundle", "exec", "rackup", "config.ru", "--host", "ssl://0.0.0.0:3000?key=/app/keys/tls.key&cert=/app/keys/tls.crt"]
