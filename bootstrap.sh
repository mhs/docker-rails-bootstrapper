#!/bin/sh
set -eu

# TODO:
# add README.md
# consolidate docker files
# stop using database.yml, use DATABASE_URL instead
# create rails app in one directory, then change to real one
# use .bootstrap_step to record progress

if ! command -v docker-compose &> /dev/null; then
  echo "the docker-compose command is required to run this script"
  exit 1
fi

echo $'\nEnter the name of the application (lowercase, snakecase, not an existing directory)'
echo "The application will be built in a directory with this corresponding name"
echo "It will also be used to initialize your Rails app"
read -p "application name: " application_name
if [ -z "$application_name" ]; then
  echo "application name is not optional"
  exit 1
fi
if [ -d "$application_name" ]; then
  echo "directory already exists"
  exit 1
fi

echo $'\nEnter the ABSOLUTE url of the github remote this application will call "origin"'
echo "This script will automatically set up a main branch, CI actions, and push an initial commit"
echo "(e.g. github://github.com/user/repository.git)"
read -p "github url: " github_url
if [ -z "$github_url" ]; then
  echo "github url is not optional"
  exit 1
fi

echo $'\nPress return to generate a strong password for Postgres, or enter a specific one if desired'
echo "You will be able to log into your database under the user 'postgres' using this password"
echo "It will be stored in your .env file, which will not be committed by git"
read -p "password: " postgres_password
if [ -z $postgres_password ]; then
  echo "generating a password..."
  postgres_password="$(cat /dev/urandom | base64 | tr -cd "[:upper:][:lower:][:digit:]" | head -c 32)"
fi

# Set up workspace
mkdir $application_name
cd $application_name

echo $'\n== Bootstrapping Docker environment =='
curl -sLJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/support/docker-compose.bootstrap.yml 1> /dev/null
curl -sLJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/support/Dockerfile 1> /dev/null
curl -sLJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/support/.dockerignore 1> /dev/null
sed -i.bkp "s/<APPLICATION_NAME>/$application_name/g" docker-compose.bootstrap.yml
sed -i.bkp "s/<APPLICATION_NAME>/$application_name/g" Dockerfile
docker-compose -f docker-compose.bootstrap.yml build --no-cache

echo $'\n== Bootstraping Rails application =='
curl -sLJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/support/Gemfile 1> /dev/null
docker-compose -f docker-compose.bootstrap.yml run web bundle install --jobs 10 --retry 5
docker-compose -f docker-compose.bootstrap.yml run web bundle exec rails new . --database=postgresql --force

echo $'\n== Adding application Docker files =='
curl -sLJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/support/docker-compose.yml 1> /dev/null
curl -sLJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/support/docker-compose.override.yml 1> /dev/null
sed -i.bkp "s/<APPLICATION_NAME>/$application_name/g" docker-compose.yml
sed -i.bkp "s/<APPLICATION_NAME>/$application_name/g" docker-compose.override.yml
touch ./sample.docker.bashrc ./sample.docker.bash_history ./sample.docker.pry_history
touch ./docker.bashrc ./docker.bash_history ./docker.pry_history

echo $'\n== Creating .env =='
curl -sLJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/support/.env 1> /dev/null
cp .env sample.env
sed -i.bkp "s/<POSTGRES_PASSWORD>/$postgres_password/g" .env

echo $'\n== Adding and configuring default gems =='
echo "
# TODO: move automatically-installed gems to the appropriate blocks:" >> Gemfile
docker-compose run web bundle add pry-rails
docker-compose run web bundle add --group development,test pry-byebug \
                                                           rspec-rails \
                                                           factory_bot_rails \
                                                           rubocop-rails \
                                                           rubocop-rails_config rubocop-performance rubocop-rspec \
                                                           brakeman
docker-compose run web bundle exec rails generate rspec:install
mkdir -p spec/support
curl -sLo spec/support/factory_bot.rb https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/support/factory_bot.rb 1> /dev/null
curl -sLo spec/support/capybara.rb https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/support/capybara.rb 1> /dev/null
curl -sLJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/support/.rubocop.yml 1> /dev/null
curl -sLo lib/tasks/rubocop.rake https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/support/rubocop.rake 1> /dev/null
# this uncomments the corresponding line in spec/rails_helper.rb to load our spec support files
sed -i.bkp "s/# \(Dir\[Rails.root.join('spec', 'support'\)/\1/g" spec/rails_helper.rb

echo $'\n== Preparing the database =='
# TODO: use DATABASE_URL instead of overriding database.yml
# - postgres://postgres:${POSTGRES_PASSWORD}@db:5432/<app_name>_<env> ???
curl -sLo config/database.yml https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/support/database.yml 1> /dev/null
sed -i.bkp "s/<APPLICATION_NAME>/$application_name/g" config/database.yml
docker-compose run web bundle exec rails db:prepare

echo $'\n== Revising setup scripts =='
mv bin/setup bin/rails_setup
curl -sLo bin/setup https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/support/setup 1> /dev/null
chmod +x bin/setup

echo $'\n== Setting up CI =='
mkdir -p .github/workflows
curl -sLo .github/workflows/ci.yml https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/support/ci.yml 1> /dev/null
curl -sLJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/support/docker-compose.ci.yml 1> /dev/null
sed -i.bkp "s/<APPLICATION_NAME>/$application_name/g" docker-compose.ci.yml
docker-compose run web bundle exec rails rubocop:auto_correct
# this uncomments the corresponding line in config/environments/production.rb to appease brakeman
sed -i.bkp "s/ # \(config.force_ssl = true\)/\1/g" config/environments/production.rb

echo $'\n== Setting up review apps =='
curl -sLJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/support/heroku.yml 1> /dev/null
curl -sLJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/support/app.json 1> /dev/null
curl -sLJO https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/support/heroku.Dockerfile 1> /dev/null
sed -i.bkp "s/<APPLICATION_NAME>/$application_name/g" heroku.Dockerfile
sed -i.bkp "s/<APPLICATION_NAME>/$application_name/g" app.json
# wonkiness replaces e.g. "http://"" with "http:\/\/"" to escape it for use by sed
sed -i.bkp "s/<GITHUB_URL>/"${github_url//\//\\\/}"/g" app.json

echo $'\n== Sweeping the floor =='
rm -rf ./**/.*.bkp ./**/*.bkp ./docker-compose.bootstrap.yml ./test ./lib/tasks/.keep
docker-compose down

echo $'\n== Setting up git integration =='
curl -sL https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/support/additions.gitignore >> .gitignore
git checkout -b main &> /dev/null
git add .
git commit -m "Bootstrapped application"
git remote add origin $github_url
git push -u origin main
