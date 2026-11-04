# syntax=docker/dockerfile:1

# Build arguments with specific versions for better reproducibility
ARG RUBY_VERSION=3.2
ARG DISTRO_NAME=slim-bookworm

# OS, Java, Raptor and gems shared by both images, so CI tests the runtime we ship
FROM ruby:${RUBY_VERSION}-${DISTRO_NAME} AS base

WORKDIR /srv/ontoportal/ncbo_cron

# Set environment variables
ENV BUNDLE_PATH=/srv/ontoportal/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=5 \
    DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        file \
        ca-certificates \
        openjdk-17-jre-headless \
        raptor2-utils \
        wait-for-it \
        libraptor2-dev \
        build-essential \
         libxml2 \
         libxslt-dev \
         libmariadb-dev \
         git \
         curl \
         libffi-dev \
     pkg-config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN gem install bundler

COPY Gemfile* *.gemspec ./

# Install dependencies
RUN bundle install --jobs ${BUNDLE_JOBS} --retry ${BUNDLE_RETRY}

# Built by ontoportal_testkit (target: test in .ontoportal-testkit.yml).
# /app because the testkit mounts coverage at /app/coverage; gems stay in BUNDLE_PATH
FROM base AS test

WORKDIR /app

# Slice size the old CI ran with (config default: 500); small slices keep goo's sliced loading exercised
ENV GOO_SLICES=100

COPY . .

CMD ["bundle", "exec", "rake"]

# Published agroportal/ncbo_cron image. Last, so builds without a target get it
FROM base AS production

# Copy application code
COPY . .
RUN cp /srv/ontoportal/ncbo_cron/config/config.rb.sample /srv/ontoportal/ncbo_cron/config/config.rb

CMD ["/bin/bash"]
