# Use the official Ruby image as the base
FROM ubuntu:20.04
USER root


# Environment Variables
ENV RAILS_ENV production
ENV NGINX_VERSION 1.22.0
ENV PASSENGER_VERSION 6.0.17
ENV PASSENGER_NATIVE_SUPPORT_OUTPUT_DIR /opt/nginx/passenger-native-support
ENV RBENV_ROOT /opt/ruby-build
ENV PATH "${RBENV_ROOT}/shims:/app/bin:${PATH}"

# Setup timezone data
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    bash \
    curl \
    jq \
    git \
    wget \
    tar \
    patch \
    make \
    libboost-all-dev \
    libcurl4-openssl-dev \
    libjemalloc-dev \
    openssl \
    libssl-dev \
    unzip \
    python3 \
    python3-pip

RUN apt update; apt upgrade
RUN apt install -y letsencrypt
RUN apt install -y python3.8-venv
RUN PYTHON_DIR=`which python3`; ln -s $PYTHON_DIR /usr/bin/python
RUN pip3 install certbot certbot_dns_route53 pyopenssl --upgrade
RUN apt install -y postgresql-contrib libpq-dev


# Install RBENV
RUN git clone https://github.com/rbenv/rbenv.git $RBENV_ROOT
WORKDIR /usr/bin
RUN ln -s ${RBENV_ROOT}/bin/rbenv rbenv; echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh; rbenv init -;

# Install Ruby-build
RUN git clone https://github.com/rbenv/ruby-build.git ${RBENV_ROOT}/plugins/ruby-build

# Install Ruby Versions
RUN RUBY_CONFIGURE_OPTS=--with-jemalloc rbenv install 2.7.6; ln -s ${RBENV_ROOT}/versions/2.7.6 ${RBENV_ROOT}/versions/2.7; rbenv rehash
RUN RUBY_CONFIGURE_OPTS=--with-jemalloc rbenv install 3.0.5; ln -s ${RBENV_ROOT}/versions/3.0.5 ${RBENV_ROOT}/versions/3.0; rbenv rehash
RUN RUBY_CONFIGURE_OPTS=--with-jemalloc rbenv install 3.1.3; ln -s ${RBENV_ROOT}/versions/3.1.3 ${RBENV_ROOT}/versions/3.1; rbenv rehash
RUN RUBY_CONFIGURE_OPTS=--with-jemalloc rbenv install 3.2.2; ln -s ${RBENV_ROOT}/versions/3.2.2 ${RBENV_ROOT}/versions/3.2; rbenv rehash
ENV RBENV_VERSION 2.7.6
RUN rbenv exec gem install bundler:2.3.26
ENV RBENV_VERSION 3.0.5
RUN rbenv exec gem install bundler:2.3.26
ENV RBENV_VERSION 3.1.3
RUN rbenv exec gem install bundler:2.3.26
ENV RBENV_VERSION=''

RUN echo "2.7.6" > ${RBENV_ROOT}/version
RUN rbenv rehash

# Passenger/nginx
RUN gem install passenger -v ${PASSENGER_VERSION}
RUN rbenv rehash
RUN mkdir -p /opt/nginx/src
RUN chmod 755 /opt/nginx/src
WORKDIR /opt/nginx/src
COPY ./k8files/fipsmode.patch .
RUN chmod 644 /opt/nginx/src/fipsmode.patch
WORKDIR /opt/nginx/src
RUN wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
RUN tar zxpf nginx-${NGINX_VERSION}.tar.gz
WORKDIR nginx-$NGINX_VERSION
RUN patch -p1 < ../fipsmode.patch
RUN mkdir -p /opt/nginx/src/headers-more-nginx-module-0.34
WORKDIR /opt/nginx/src
RUN wget -O headers-more-nginx-module-0.34.tar.gz https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/v0.34.tar.gz
RUN tar xzvf headers-more-nginx-module-0.34.tar.gz

RUN rbenv exec passenger-install-nginx-module \
               --auto \
               --nginx-source-dir="/opt/nginx/src/nginx-${NGINX_VERSION}" \
               --languages ruby \
               --prefix=/opt/nginx \
               --extra-configure-flags="--with-ipv6 --with-http_stub_status_module --with-http_ssl_module --with-http_realip_module --with-ld-opt=\"-L/usr/lib/x86_64-linux-gnu/lib\" --with-cc-opt=\"-I/usr/include/x86_64-linux-gnu/openssl\" --add-module=/opt/nginx/src/headers-more-nginx-module-0.34"  
RUN rbenv rehash
RUN rbenv exec passenger-config compile-agent
RUN rbenv rehash
RUN mkdir -p /var/log/nginx
RUN chmod 750 /var/log/nginx
RUN ln -s /var/log/nginx /opt/nginx/logs
RUN mkdir -p /opt/nginx/conf/conf.d
RUN chmod 755 /opt/nginx/conf/conf.d
RUN mkdir -p /opt/nginx/conf/sites.d
RUN chmod 755 /opt/nginx/conf/sites.d
RUN mkdir -p /opt/nginx/passenger-native-support
RUN chmod 755 /opt/nginx/passenger-native-support
WORKDIR /opt/nginx
COPY ./k8files/compile-passenger-module .
RUN /opt/nginx/compile-passenger-module ALL
COPY ./k8files/status-map.conf ./conf/
RUN chmod 644 ./conf/status-map.conf

# Copy and configure nginx conf
COPY ./k8files/nginx.conf ./conf/
RUN chmod 644 ./conf/nginx.conf
SHELL ["/bin/bash", "-c"]
RUN PASSENGER_ROOT=`rbenv exec passenger-config --root`; sed -i "s~<PASSENGER_ROOT_PLACEHOLDER>~${PASSENGER_ROOT};~g" ./conf/nginx.conf
RUN IP4_LIST=(`curl -s https://ip-ranges.amazonaws.com/ip-ranges.json | jq -r '.prefixes[] | select(.service=="CLOUDFRONT_ORIGIN_FACING") | .ip_prefix'`); IP4_FORMATTED_LIST=(); for i in "${IP4_LIST[@]}"; do IP4_FORMATTED_LIST+=("  set_real_ip_from $i;"); done; sed -i '/<REAL_IP4_PLACEHOLDER>/r'<(printf %s\\n "${IP4_FORMATTED_LIST[@]}") ./conf/nginx.conf; sed -i '/<REAL_IP4_PLACEHOLDER>/d' ./conf/nginx.conf
RUN IP6_LIST=(`curl -s https://ip-ranges.amazonaws.com/ip-ranges.json | jq -r '.ipv6_prefixes[] | select(.service=="CLOUDFRONT") | .ipv6_prefix'`); IP6_FORMATTED_LIST=(); for i in "${IP6_LIST[@]}"; do IP6_FORMATTED_LIST+=("  set_real_ip_from $i;"); done; sed -i '/<REAL_IP6_PLACEHOLDER>/r'<(printf %s\\n "${IP6_FORMATTED_LIST[@]}") ./conf/nginx.conf; sed -i '/<REAL_IP6_PLACEHOLDER>/d' ./conf/nginx.conf

WORKDIR /etc/init.d
COPY ./k8files/passenger.init ./passenger
RUN chmod 755 ./passenger
RUN chown root: ./passenger

WORKDIR /etc/default
COPY ./k8files/passenger.default ./passenger
RUN chmod 644 ./passenger
RUN chown root: ./passenger

WORKDIR /opt/nginx/conf/sites.d
COPY ./k8files/status.conf .
RUN chmod 644 ./status.conf

RUN update-rc.d passenger defaults
RUN update-rc.d passenger enable

# Install AWS CLI
WORKDIR /
RUN curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
RUN unzip awscli-bundle.zip
RUN ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

# Certbot
# push_letsencrypt_certs.sh script has an environment plugged in that used to be a variable. For Review apps, it's set to 'reviewapp' for now. Will probably need to be updated based on the s3 bucket created for review app certs. Account ID and Region are also currently hardcoded for sandbox in us-west-2
COPY ./k8files/push_letsencrypt_certs.sh ./usr/local/bin
RUN chown root: ./usr/local/bin/push_letsencrypt_certs.sh
RUN chmod 755 ./usr/local/bin/push_letsencrypt_certs.sh
COPY ./k8files/update_letsencrypt_certs ./usr/local/bin

RUN chown root: ./usr/local/bin/update_letsencrypt_certs
RUN chmod 755 ./usr/local/bin/update_letsencrypt_certs
RUN ./usr/local/bin/update_letsencrypt_certs
RUN echo '@daily root flock -n /tmp/update_letsencrypt_certs.lock -c /usr/local/bin/update_letsencrypt_certs' > /etc/cron.d/update_letsencrypt_certs
RUN chown root: /etc/cron.d/update_letsencrypt_certs
RUN chmod 700 /etc/cron.d/update_letsencrypt_certs

# DHParam
#RUN aws s3 cp s3://login-gov.secrets.894947205914-us-west-2/reviewapp/dhparam /etc/ssl/certs/dhparam.pem

# Certs


# Copy and install Gems

# Copy Application Code
RUN groupadd --system appinstall; \
    useradd --gid appinstall --system -d /home/appinstall --create-home --shell /usr/sbin/nologin appinstall; \
    chmod 755 /home/appinstall; chown appinstall: /home/appinstall
RUN groupadd --system websrv; \
    useradd --gid websrv --system -d /home/websrv --create-home --shell /usr/sbin/nologin websrv; \
    chmod 755 /home/websrv; chown websrv: /home/websrv

RUN mkdir -p /srv/pki-rails/shared; chown -R appinstall: /srv/pki-rails/shared
RUN export RELEASE_DATE=`date +%Y%m%d%H%M%S`
RUN mkdir -p /srv/pki-rails/releases/${RELEASE_DATE}; chown -R appinstall: /srv/pki-rails/releases/${RELEASE_DATE}
WORKDIR /srv/pki-rails/releases/${RELEASE_DATE}
COPY . .
RUN chown -R appinstall /srv/pki-rails/releases/${RELEASE_DATE}/*
RUN mkdir -p /usr/local/share/aws; chmod -R 755 /usr/local/share/aws
RUN wget -P /usr/local/share/aws/ https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem; chmod 755 /usr/local/share/aws/rds-combined-ca-bundle.pem
RUN mkdir -p /srv/pki-rails/shared/config/certs
RUN chown websrv:appinstall /srv/pki-rails/shared/config/certs

RUN ln -s /srv/pki-rails/releases/$RELEASE_DATE /srv/pki-rails/current
RUN mkdir -p /svr/pki-rails/current/tmp; chown -R appinstall /svr/pki-rails/current/tmp

USER appinstall
RUN rbenv exec bundle install --deployment --jobs 3 --path /srv/pki-rails/shared/bundle --without deploy development test
RUN rbenv exec bundle exec bin/activate

RUN ln -s /srv/pki-rails/shared/log /srv/pki-rails/current/log
RUN ln -s /srv/pki-rails/shared/tmp/cache /svr/pki-rails/current/tmp/cache
RUN ln -s /srv/pki-rails/shared/tmp/pids /svr/pki-rails/current/tmp/pids
RUN ln -s /srv/pki-rails/shared/tmp/sockets /svr/pki-rails/current/tmp/sockets

USER root

WORKDIR /
COPY ./k8files/pivcac.conf /opt/nginx/conf/sites.d/

WORKDIR /srv/pki-rails/current/public
RUN RUBY_DIR=`rbenv which ruby`; sed -i "s~<RUBY_VERSION_PLACEHOLDER>~${RUBY_DIR};~g" /opt/nginx/conf/sites.d/pivcac.conf

WORKDIR /srv/pki-rails/shared
RUN mkdir -p ./config; chown -R websrv:appinstall ./config
RUN mkdir -p ./log; chown -R websrv:appinstall ./log; chmod -R 0755 ./log
RUN mkdir -p ./tmp/cache; chown -R websrv:appinstall ./tmp/cache; chmod -R 0755 ./tmp/cache
RUN mkdir -p ./tmp/pids; chown -R websrv:appinstall ./tmp/pids; chmod -R 0755 ./tmp/pids
RUN mkdir -p ./tmp/sockets; chown -R websrv:appinstall ./tmp/sockets; chmod -R 0755 ./tmp/sockets

USER appinstall
WORKDIR /srv/pki-rails/current
#RUN rbenv exec bundle exec rake db:create db:migrate:monitor_concurrent --trace

USER root
RUN touch /srv/pki-rails/current/config/application.yml
RUN chgrp websrv /srv/pki-rails/current/config/application.yml
RUN chown -R websrv /srv/pki-rails/shared/log

RUN mkdir -p /srv/pki-rails/current/public/api; chown -R appinstall /srv/pki-rails/current/public/api
# THIS IS A STAND-IN deploy.json UNTIL A REAL ONE CAN BE WIRED IN
RUN echo '{' > /srv/pki-rails/current/public/api/deploy.json; \
    echo '  "env": "reviewapp",' >> /srv/pki-rails/current/public/api/deploy.json; \
    echo '  "branch": "test",' >> /srv/pki-rails/current/public/api/deploy.json; \
    echo '  "user": "test",' >> /srv/pki-rails/current/public/api/deploy.json; \
    echo '  "git_sha": "test",' >> /srv/pki-rails/current/public/api/deploy.json; \
    echo '  "git_date": "2023-05-10T00:00:00+00:00",' >> /srv/pki-rails/current/public/api/deploy.json; \
    echo '  "chef_run_timestamp": "20230510000000",' >> /srv/pki-rails/current/public/api/deploy.json; \
    echo '  "instance_id": "i-9999999999",' >> /srv/pki-rails/current/public/api/deploy.json; \
    echo '  "sha": "8b026895c1094a2618223668b7ff0859c32b2d28",' >> /srv/pki-rails/current/public/api/deploy.json; \
    echo '  "timestamp": "20230510000000",' >> /srv/pki-rails/current/public/api/deploy.json; \
    echo '  "devops_git_sha": "701af43b8e55f2f303616d5d07df24e036b05a54",' >> /srv/pki-rails/current/public/api/deploy.json; \
    echo '  "devops_git_date": "2023-05-10T00:00:00+00:00"' >> /srv/pki-rails/current/public/api/deploy.json; \
    echo '}' >> /srv/pki-rails/current/public/api/deploy.json

COPY ./k8files/update_cert_revocations /usr/local/bin

RUN chown root: /usr/local/bin/update_cert_revocations
RUN chmod 755 /usr/local/bin/update_cert_revocations
RUN echo '* */4 * * * websrv flock -n /tmp/update_cert_revocations.lock -c /usr/local/bin/update_cert_revocations' > /etc/cron.d/update_cert_revocations
RUN chown root: /etc/cron.d/update_cert_revocations
RUN chmod 700 /etc/cron.d/update_cert_revocations

# Run Server
RUN service passenger start
