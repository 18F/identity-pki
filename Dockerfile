# Use the official Ruby image because the Rails images have been deprecated
FROM ruby:2.6

# Enable https
RUN apt-get update
RUN apt-get install -y apt-transport-https

# Install Postgres client
RUN apt-get install -y --no-install-recommends postgresql-client
RUN rm -rf /var/lib/apt/lists/*

# Everything happens here from now on   
WORKDIR /pivcac

# Simple Gem cache.  Success here creates a new layer in the image.
COPY Gemfile .
COPY Gemfile.lock .
RUN gem install bundler --conservative
RUN bundle install --without deploy production

# Copy everything else over
COPY . .

# Up to this point we've been root, change to a lower priv. user
RUN groupadd -r appuser
RUN useradd --system --create-home --gid appuser appuser
RUN chown -R appuser.appuser /pivcac
USER appuser

EXPOSE 8443
CMD ["thin", "start", "-p", "8443", "--ssl", "--ssl-key-file", "config/local-certs/server.key", "--ssl-cert-file", "config/local-certs/server.crt"]
