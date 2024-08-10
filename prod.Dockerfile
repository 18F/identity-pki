# this part builds everything
FROM ruby:3.2.2-slim-bullseye as builder

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

# Install and configure nginx
RUN mkdir -p /opt/nginx/src; \
    chmod 755 /opt/nginx/src; \
    mkdir -p /var/log/nginx; \
    chmod 755 /var/log/nginx; \
    ln -s /var/log/nginx/ /opt/nginx/logs; \
    wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -P /opt/nginx/src; \
    tar zxpf /opt/nginx/src/nginx-${NGINX_VERSION}.tar.gz -C /opt/nginx/src;
COPY --chmod=644 ./k8files/fipsmode.patch /opt/nginx/src
RUN patch -d /opt/nginx/src/nginx-${NGINX_VERSION} -p1 < /opt/nginx/src/fipsmode.patch; \
    mkdir -p /opt/nginx/src/headers-more-nginx-module-0.34; \
    wget --no-proxy -O /opt/nginx/src/headers-more-nginx-module-0.34.tar.gz https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/v0.34.tar.gz; \
    tar xzvf /opt/nginx/src/headers-more-nginx-module-0.34.tar.gz -C /opt/nginx/src;
WORKDIR /opt/nginx/src/nginx-${NGINX_VERSION}
RUN ./configure --sbin-path=/usr/local/nginx/nginx --prefix=/opt/nginx --with-http_ssl_module --with-ipv6 --with-http_stub_status_module --with-http_realip_module --with-ld-opt="-L/usr/lib/x86_64-linux-gnu" --with-cc-opt="-I/usr/include/x86_64-linux-gnu/openssl" --add-module=/opt/nginx/src/headers-more-nginx-module-0.34 && \
    make && \
    make install

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

# set IPs up in nginx.conf
WORKDIR /tmp
COPY k8files/nginx.conf /opt/nginx/conf/nginx.conf
RUN curl -s https://ip-ranges.amazonaws.com/ip-ranges.json | jq -r '.prefixes[] | select(.service=="CLOUDFRONT_ORIGIN_FACING") | .ip_prefix' | awk '{printf("  set_real_ip_from %s;\n",$1)}' > /tmp/ips.out && \
    sed -i '/<REAL_IP4_PLACEHOLDER>/r /tmp/ips.out' /opt/nginx/conf/nginx.conf && \
    sed -i '/<REAL_IP4_PLACEHOLDER>/d' /opt/nginx/conf/nginx.conf
RUN curl -s https://ip-ranges.amazonaws.com/ip-ranges.json | jq -r '.ipv6_prefixes[] | select(.service=="CLOUDFRONT") | .ipv6_prefix' | awk '{printf("  set_real_ip_from %s;\n",$1)}' > /tmp/ips.out && \
    sed -i '/<REAL_IP6_PLACEHOLDER>/r /tmp/ips.out' /opt/nginx/conf/nginx.conf && \
    sed -i '/<REAL_IP6_PLACEHOLDER>/d' /opt/nginx/conf/nginx.conf



#####################################################
# here is where the actual image gets built
FROM ruby:3.2.2-slim-bullseye

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
    letsencrypt \
    postgresql-contrib \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

RUN PYTHON_DIR=`which python3`; ln -s $PYTHON_DIR /usr/bin/python; \
    pip3 install certbot certbot_dns_route53 pyopenssl

# Create user and setup working directory
RUN addgroup --gid 1000 app && \
    adduser --uid 1000 --gid 1000 --disabled-password --gecos "" app && \
    mkdir -p $RAILS_ROOT && \
    mkdir -p $RAILS_ROOT/tmp/pids && \
    mkdir -p $RAILS_ROOT/log

# Copy scripts
COPY --chown=root:root --chmod=755 ./k8files/update_cert_revocations /usr/local/bin
COPY --chown=root:root --chmod=755 ./k8files/push_letsencrypt_certs.sh /usr/local/bin/push_letsencrypt_certs.sh
COPY --chown=root:root --chmod=755 ./k8files/update_letsencrypt_certs /usr/local/bin/update_letsencrypt_certs
COPY --chown=root:root --chmod=755 ./k8files/configure_environment /usr/local/bin/configure_environment

# install nginx from build
COPY --from=builder /usr/local/nginx /usr/local/nginx
COPY --from=builder /opt/nginx /opt/nginx
COPY --from=builder /var/log/nginx /var/log/nginx
RUN ln -s /usr/local/nginx/nginx /usr/local/sbin/nginx; \
    mkdir -p /opt/nginx/conf/conf.d; \
    chmod 755 /opt/nginx/conf/conf.d; \
    mkdir -p /opt/nginx/conf/sites.d; \
    chmod 755 /opt/nginx/conf/sites.d;
COPY --chmod=644 ./k8files/status-map.conf /opt/nginx/conf/
COPY --chmod=644 ./k8files/status.conf /opt/nginx/conf/sites.d/
# this is actually kinda a placeholder, meant to be mounted over
COPY ./k8files/pivcac.conf /opt/nginx/conf/sites.d/pivcac.conf

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
COPY --chmod=644 ./k8files/application.yml.default.docker ./config/application.yml
COPY --chmod=644 ./k8files/newrelic.yml ./config/newrelic.yml
COPY --chmod=755 ./k8files/puma_production ./config/puma/production.rbtemp

# set bundler up
RUN bundle config build.nokogiri --use-system-libraries
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
ENTRYPOINT ["bundle", "exec", "rackup", "config.ru", "--host", "ssl://0.0.0.0:3000?key=/app/keys/localhost.key&cert=/app/keys/localhost.crt"]
