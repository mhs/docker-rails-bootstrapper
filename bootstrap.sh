#!/bin/sh
set -eux

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
docker-compose -f docker-compose.bootstrap.yml build --no-cache

# Bootstrap Rails application
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/Gemfile
docker-compose -f docker-compose.bootstrap.yml run web bundle install --jobs 10 --retry 5
docker-compose -f docker-compose.bootstrap.yml run web bundle exec rails new . --database=postgresql --force

# Swap bootstrapping docker files for application docker files
rm -f docker-compose.bootstrap.yml
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/docker-compose.yml
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/docker-compose.override.yml
sed -i.bkp "s/<APPLICATION_NAME>/$application_name/g" docker-compose.yml
sed -i.bkp "s/<APPLICATION_NAME>/$application_name/g" docker-compose.override.yml
touch ./sample.docker.bashrc ./sample.docker.bash_history
touch ./docker.bashrc ./docker.bash_history

# append to .gitignore
curl -L https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/additions.gitignore >> .gitignore

# create, populate .env
curl -LJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/.env
echo "Press return to generate a strong password for Postgres, or enter one if desired:"
read -p "password: " postgres_password
if [ -z $postgres_password ]
then
  echo "generating a password..."
  postgres_password="$(cat /dev/urandom | base64 | tr -cd "[:upper:][:lower:][:digit:]" | head -c 32)"
fi
sed -i.bkp "s/<POSTGRES_PASSWORD>/$postgres_password/g" .env

# migrate the database and run setup
curl -Lo config/database.yml https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/database.yml
sed -i.bkp "s/<APPLICATION_NAME>/$application_name/g" config/database.yml
docker-compose run web bundle exec rails db:create db:migrate

# cleanup
rm -f *.bkp
