# Use the official Ruby image as the base
FROM ruby:3.2.2-alpine

#Environment Variables
ENV http_proxy http://obproxy.login.gov.internal:3128
ENV https_proxy http://obproxy.login.gov.internal:3128
ENV no_proxy localhost,127.0.0.1,169.254.169.254,169.254.169.123,.login.gov.internal,ec2.us-west-2.amazonaws.com,kms.us-west-2.amazonaws.com,secretsmanager.us-west-2.amazonaws.com,ssm.us-west-2.amazonaws.com,ec2messages.us-west-2.amazonaws.com,lambda.us-west-2.amazonaws.com,ssmmessages.us-west-2.amazonaws.com,sns.us-west-2.amazonaws.com,sqs.us-west-2.amazonaws.com,events.us-west-2.amazonaws.com,metadata.google.internal,sts.us-west-2.amazonaws.com
ENV RAILS_ENV production
ENV PATH "/app/bin:${PATH}"

# Install dependencies
RUN apk update

#TODO: Install/configure AWS CloudWatch Agent/SSM Agent? Is it needed in EKS? Probably not SSM. Probably still need CloudWatch.

# Generate Certs?

# SSM Documents?

# New Relic and Nessus config?

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
CMD ["thin", "start", "-p", "8443", "--ssl", "--ssl-key-file", "config/local-certs/server.key", "--ssl-cert-file", "config/local-certs/server.crt"]
