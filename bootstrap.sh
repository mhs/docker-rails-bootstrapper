#!/bin/sh
set -eux

# TODO:
# check for compose upfront
# forward args to rails new

echo $'\n=== Downloading bootstrapping files ==='
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/docker-compose.bootstrap.yml
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/Dockerfile
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/.dockerignore

echo $'\n=== Bootstrapping Rails application ==='
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/Gemfile
docker-compose -f docker-compose.bootstrap.yml build --no-cache
docker-compose -f docker-compose.bootstrap.yml run web bundle install
docker-compose -f docker-compose.bootstrap.yml run web bundle exec rails new . --database=postgresql

echo $'\n=== Swapping bootstrapping files for actual files ==='
rm -f docker-compose.bootstrap.yml
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/docker-compose.yml
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/docker-compose.override.yml
