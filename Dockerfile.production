# syntax=docker/dockerfile:1

# Build arguments with specific versions for better reproducibility
ARG RUBY_VERSION=3.1
ARG DISTRO_NAME=slim-bookworm

FROM ruby:${RUBY_VERSION}-${DISTRO_NAME}

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

# Copy application code
COPY . .
RUN cp /srv/ontoportal/ncbo_cron/config/config.rb.sample /srv/ontoportal/ncbo_cron/config/config.rb

CMD ["/bin/bash"]
