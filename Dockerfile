# syntax=docker/dockerfile:1

# Build stage
ARG RUBY_VERSION=3.1
ARG DISTRO_NAME=slim-bookworm
FROM ruby:${RUBY_VERSION}-${DISTRO_NAME} AS builder

WORKDIR /srv/ontoportal/ncbo_cron

# Set environment variables for build phase
ENV BUNDLE_PATH=/srv/ontoportal/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=5 \
    DEBIAN_FRONTEND=noninteractive

# Install build dependencies only
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        libxml2-dev \
        libxslt-dev \
        libmariadb-dev \
        libffi-dev \
        libraptor2-dev \
        pkg-config \
        git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install bundler and dependencies
RUN gem install bundler

# Copy only the Gemfile-related files first to leverage Docker cache
COPY Gemfile* *.gemspec ./

# Install gems
RUN bundle install --jobs ${BUNDLE_JOBS} --retry ${BUNDLE_RETRY} \
    && bundle clean --force \
    && find ${BUNDLE_PATH} -name "*.c" -delete \
    && find ${BUNDLE_PATH} -name "*.o" -delete \
    && find ${BUNDLE_PATH} -name ".git" -type d -exec rm -rf {} + 2>/dev/null || true

# Final stage
FROM ruby:${RUBY_VERSION}-${DISTRO_NAME} AS app

WORKDIR /srv/ontoportal/ncbo_cron

# Set environment variables for runtime
ENV BUNDLE_PATH=/srv/ontoportal/bundle \
    DEBIAN_FRONTEND=noninteractive

# Install only runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        openjdk-17-jre-headless \
        raptor2-utils \
        wait-for-it \
        libxml2 \
        libxslt1.1 \
        libmariadb3 \
        libraptor2-0 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy bundled gems from builder stage
COPY --from=builder ${BUNDLE_PATH} ${BUNDLE_PATH}

# Copy application code
COPY . .

# Configure the application
RUN cp /srv/ontoportal/ncbo_cron/config/config.rb.sample /srv/ontoportal/ncbo_cron/config/config.rb

# Set the default command
CMD ["/bin/bash"]