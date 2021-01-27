#!/bin/sh
#set -euxo pipefail

# TODO:
# check for compose upfront
# forward args to rails new

# Downloading bootstrapping files
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/docker-compose.bootstrap.yml
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/Dockerfile
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/.dockerignore

# Bootstrapping Rails application
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/Gemfile
docker-compose -f docker-compose.bootstrap.yml build --no-cache
docker-compose -f docker-compose.bootstrap.yml run web bash -c "bundle install --jobs 10 --retry 5"
echo "hello!"
docker-compose -f docker-compose.bootstrap.yml run web bash -c "bundle exec rails new . --database=postgresql --force"

# Swapping bootstrapping files for actual files
rm -f docker-compose.bootstrap.yml
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/docker-compose.yml
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/docker-compose.override.yml
