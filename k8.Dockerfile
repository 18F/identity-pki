FROM ruby:3.2.2-slim-bullseye

SHELL ["/bin/bash", "-c"]

# Set environment variables
ENV RAILS_ROOT /app
ENV RAILS_ENV production
ENV BUNDLE_PATH /usr/local/bundle
ENV NGINX_VERSION 1.22.0

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
    apt-transport-https \
    build-essential \
    ca-certificates \
    cron \
    curl \    
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
    vim \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN apt update; apt upgrade; \
    apt install -y letsencrypt postgresql-contrib libpq-dev sudo; \
    PYTHON_DIR=`which python3`; ln -s $PYTHON_DIR /usr/bin/python; \
    pip3 install certbot certbot_dns_route53 pyopenssl --upgrade

RUN curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "/awscli-bundle.zip"; \
    unzip /awscli-bundle.zip -d/; \
    ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

RUN mkdir -p /etc/apt/keyrings/; \
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

RUN echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

RUN apt-get update && apt-get install -y kubectl

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
COPY --chown=root:root --chmod=755 ./k8files/push_letsencrypt_certs.sh /usr/local/bin/push_letsencrypt_certs.sh
COPY --chown=root:root --chmod=755 ./k8files/update_letsencrypt_certs /usr/local/bin/update_letsencrypt_certs
COPY --chown=root:root --chmod=755 ./k8files/configure_environment /usr/local/bin/configure_environment

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

RUN ln -s /usr/local/nginx/nginx /usr/local/sbin/nginx; \
    mkdir -p /opt/nginx/conf/conf.d; \
    chmod 755 /opt/nginx/conf/conf.d; \
    mkdir -p /opt/nginx/conf/sites.d; \
    chmod 755 /opt/nginx/conf/sites.d;
COPY --chmod=644 ./k8files/status-map.conf /opt/nginx/conf/
COPY --chmod=644 ./k8files/nginx.conf /opt/nginx/conf/
COPY --chmod=644 ./k8files/status.conf /opt/nginx/conf/sites.d/
COPY ./k8files/pivcac.conf /opt/nginx/conf/sites.d/pivcac.conftemp

# Download RDS Combined CA Bundles
RUN wget -P /usr/local/share/aws/  https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem

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
    mkdir -p ${RAILS_ROOT}/tmp/sockets; chmod -R 0755 ${RAILS_ROOT}/tmp/sockets; \
    mkdir -p ${RAILS_ROOT}/config/puma; chmod -R 0755 ${RAILS_ROOT}/config/puma; 
COPY --chown=app --chmod=755 ./k8files/application.yml.default.docker ./config/application.yml
COPY --chown=app --chmod=755 ./k8files/newrelic.yml ./config/newrelic.yml
COPY --chown=app --chmod=755 ./k8files/puma_production ./config/puma/production.rbtemp

# Expose port the app runs on
EXPOSE 443

ENTRYPOINT ["/usr/local/bin/configure_environment"]
