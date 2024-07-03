# Use the official Ruby image because the Rails images have been deprecated
FROM ruby:3.3.1-slim as build

RUN apt-get update && \
    apt-get install -y \
    git-core \
    build-essential \
    git-lfs \
    curl \
    zlib1g-dev \
    libssl-dev \
    libreadline-dev \
    libyaml-dev \
    libsqlite3-dev \
    sqlite3 \
    libxml2-dev \
    libxslt1-dev \
    libcurl4-openssl-dev \
    software-properties-common \
    libffi-dev \
    libpq-dev \
    xz-utils \
    unzip && \
    rm -rf /var/lib/apt/lists/*

# Everything happens here from now on
WORKDIR /pivcac

# Simple Gem cache.  Success here creates a new layer in the image.
COPY Gemfile* ./
RUN gem install bundler --conservative && \
    bundle install --without deploy production


# Switch to base image
FROM ruby:3.3.1-slim
WORKDIR /pivcac

RUN apt-get update && \
    apt-get install -y \
    curl \
    zlib1g-dev \
    libssl-dev \
    libreadline-dev \
    libyaml-dev \
    libxml2-dev \
    libxslt1-dev \
    libcurl4-openssl-dev \
    libffi-dev \
    libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy Gems, NPMs, and other relevant items from build layer
COPY --from=build /pivcac .

# Copy in whole source (minus items matched in .dockerignore)
COPY . .

# Create a new user and set up the working directory
RUN addgroup --gid 1000 app && \
    adduser --uid 1000 --gid 1000 --disabled-password --gecos "" app && \
    mkdir -p /pivcac && \
    mkdir -p /pivcac/tmp/pids && \
    mkdir -p /pivcac/log

# make everything the proper perms after everything is initialized
RUN chown -R app:app /pivcac/tmp && \
    chown -R app:app /pivcac/log && \
    find /pivcac -type d | xargs chmod 755

# get rid of suid/sgid binaries
RUN find / -perm /4000 -type f | xargs chmod u-s
RUN find / -perm /2000 -type f | xargs chmod g-s

USER app

EXPOSE 8443
CMD ["bundle", "exec", "rackup", "config.ru", "--host", "ssl://localhost:8443?key=config/local-certs/server.key&cert=config/local-certs/server.crt"]
