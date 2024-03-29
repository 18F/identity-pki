# Use the official Ruby image because the Rails images have been deprecated
FROM logindotgov/build as build

# Everything happens here from now on
WORKDIR /pivcac

# Simple Gem cache.  Success here creates a new layer in the image.
COPY Gemfile* ./
RUN gem install bundler --conservative && \
    bundle install --without deploy production

# Copy everything else over
COPY . .

# Switch to base image
FROM logindotgov/base
WORKDIR /pivcac

# Copy Gems, NPMs, and other relevant items from build layer
COPY --chown=appuser:appuser --from=build /pivcac .

# Copy in whole source (minus items matched in .dockerignore)
COPY --chown=appuser:appuser . .

USER appuser

EXPOSE 8443
CMD ["bundle", "exec", "rackup", "config.ru", "--host", "ssl://localhost:8443?key=config/local-certs/server.key&cert=config/local-certs/server.crt"]
