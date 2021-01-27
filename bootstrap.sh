#!/bin/sh
set -euxo pipefail

# TODO:
# test for existing directory
# check for compose upfront
# forward args to rails new

# Set up workspace
application_name=$1
mkdir $application_name
cd $application_name

# Bootstrap docker environment
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/docker-compose.bootstrap.yml
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/Dockerfile
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/.dockerignore
sed -i.bkp "s/<APPLICATION_NAME>/$application_name/g" docker-compose.bootstrap.yml
sed -i.bkp "s/<APPLICATION_NAME>/$application_name/g" Dockerfile
rm -f *.bkp
docker-compose -f docker-compose.bootstrap.yml build --no-cache

# Bootstrap Rails application
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/Gemfile
docker-compose -f docker-compose.bootstrap.yml run web bundle install --jobs 10 --retry 5
docker-compose -f docker-compose.bootstrap.yml run web bundle exec rails new . --database=postgresql --force

# Swapping bootstrapping files for actual files
rm -f docker-compose.bootstrap.yml
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/docker-compose.yml
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/docker-compose.override.yml
sed -i.bkp "s/<APPLICATION_NAME>/$application_name/g" docker-compose.yml
sed -i.bkp "s/<APPLICATION_NAME>/$application_name/g" docker-compose.override.yml
rm -f *.bkp
