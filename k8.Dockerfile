FROM ruby:3.0.5-slim

# Set environment variables
ENV RAILS_ROOT /app
ENV RAILS_ENV production
ENV BUNDLE_PATH /usr/local/bundle

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
    build-essential \
    cron \
    curl \    
    git-core \
    tar \ 
    unzip \
    libcurl4-openssl-dev \
    libssl-dev \
    libpq-dev \
    python3 \
    python3-pip \
    python3-venv \
    util-linux \
    && rm -rf /var/lib/apt/lists/*

RUN apt update; apt upgrade; \
    apt install -y postgresql-contrib libpq-dev sudo; \
    PYTHON_DIR=`which python3`; ln -s $PYTHON_DIR /usr/bin/python; \
    pip3 install certbot certbot_dns_route53 pyopenssl --upgrade

RUN curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "/awscli-bundle.zip"; \
    unzip /awscli-bundle.zip -d/; \
    ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

# Create user and setup working directory
RUN addgroup --gid 1000 app && \
    adduser --uid 1000 --gid 1000 --disabled-password --gecos "" app && \
    usermod -aG sudo app && \
    mkdir -p $RAILS_ROOT && \
    mkdir -p $BUNDLE_PATH && \
    chown -R app:app $RAILS_ROOT && \
    chown -R app:app $BUNDLE_PATH && \
    echo "app ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/app

# Copy scripts
COPY --chown=root:root --chmod=755 ./k8files/update_cert_revocations /usr/local/bin

# Create cron jobs
RUN echo '* */4 * * * websrv flock -n /tmp/update_cert_revocations.lock -c /usr/local/bin/update_cert_revocations' > /etc/cron.d/update_cert_revocations; \
    chown root: /etc/cron.d/update_cert_revocations; \
    chmod 700 /etc/cron.d/update_cert_revocations

# Create working directory
WORKDIR $RAILS_ROOT

USER app

COPY .ruby-version $RAILS_ROOT/.ruby-version
COPY Gemfile $RAILS_ROOT/Gemfile
COPY Gemfile.lock $RAILS_ROOT/Gemfile.lock

RUN bundle config build.nokogiri --use-system-libraries
RUN bundle config set --local deployment 'true'
RUN bundle config set --local path $BUNDLE_PATH
RUN bundle config set --local without 'deploy development doc test'
RUN bundle install --jobs $(nproc)
RUN bundle binstubs --all

COPY package.json $RAILS_ROOT/package.json

# Copy Application Code
COPY --chown=app:app ./lib ./lib
COPY --chown=app:app ./app ./app
COPY --chown=app:app ./config ./config
COPY --chown=app:app ./config.ru ./config.ru
COPY --chown=app:app ./db ./db
COPY --chown=app:app ./bin ./bin
COPY --chown=app:app ./public ./public
COPY --chown=app:app ./spec ./spec
COPY --chown=app:app ./vendor ./vendor
COPY --chown=app:app ./Rakefile ./Rakefile
COPY --chown=app:app ./Makefile ./Makefile
COPY --chown=app:app ./Procfile ./Procfile
COPY --chown=app:app ./log ./log
COPY --chown=app:app ./tmp ./tmp
RUN mkdir -p ${RAILS_ROOT}/keys; chmod -R 0755 ${RAILS_ROOT}/keys; \
    mkdir -p ${RAILS_ROOT}/tmp/cache; chmod -R 0755 ${RAILS_ROOT}/tmp/cache; \
    mkdir -p ${RAILS_ROOT}/tmp/pids; chmod -R 0755 ${RAILS_ROOT}/tmp/pids; \
    mkdir -p ${RAILS_ROOT}/tmp/sockets; chmod -R 0755 ${RAILS_ROOT}/tmp/sockets;

COPY --chown=appinstall --chmod=755 ./k8files/application.yml.default.docker ./config/application.yml

# Generate and place SSL certificates for Puma
RUN openssl req -x509 -sha256 -nodes -newkey rsa:2048 -days 1825 \
    -keyout $RAILS_ROOT/keys/localhost.key \
    -out $RAILS_ROOT/keys/localhost.crt \
    -subj "/C=US/ST=Fake/L=Fakerton/O=Dis/CN=localhost"

# Expose port the app runs on
EXPOSE 3001

USER root
