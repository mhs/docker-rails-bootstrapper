# TRICKY: this file is necessarily different than the one used in other environments due to Heroku's lack of support
# for crucial Docker infrastructure (e.g. Volumes). As many steps as possible should be made to match those in the
# usual Dockerfile when changes are made

FROM ruby:2.7.4-bullseye

# set up app root
WORKDIR /root/<APPLICATION_NAME>

# Add wait script to the image
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.9.0/wait ../wait
RUN chmod +x ../wait

# pin to node v16 instead of debian default
# this is the most recent LTS node version as of 2021-11
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
# update apt package lists
    apt-get update && \
# install packages
#  - nodejs for npm registry access
#  - less for paging in dev consoles
    apt-get install nodejs less

# install yarn for package management
RUN npm install -g yarn && \
# set yarn version
    yarn set version berry

# install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 20 --retry 5

# install yarn packages
COPY package.json yarn.lock ./
RUN yarn install

# copy the remaining app files
ADD . .

# pack assets
RUN bundle exec rails assets:precompile
