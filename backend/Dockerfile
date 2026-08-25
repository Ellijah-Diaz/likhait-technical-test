# syntax = docker/dockerfile:1

# Use Ruby 3.3.7
ARG RUBY_VERSION=3.3.7
FROM ruby:$RUBY_VERSION-slim

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential ca-certificates default-mysql-client default-libmysqlclient-dev git libyaml-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile Gemfile.lock ./

# Configure bundler and install gems with retry logic.
#
# BUNDLE_PATH is deliberately left at its default (/usr/local/bundle). The
# official ruby images export BUNDLE_APP_CONFIG=/usr/local/bundle, so a
# `bundle config set --local path vendor/bundle` here does NOT write
# /rails/.bundle/config as it appears to -- it writes the image-global
# config, which docker-compose then carries into the container via the
# backend_gems volume. Bundler installed into /rails/vendor/bundle, which is
# bind-mounted from the host, dumping ~125MB of gems into the working tree
# while leaving /usr/local/bundle/bin (the only bundle bin directory on
# PATH) empty, so the container died with "sh: 3: rails: not found".
RUN bundle config set --local deployment 'false' && \
    bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile --gemfile app/ lib/

# Entrypoint prepares the database
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]