FROM ruby:2.7.4-bullseye

# set up app root
WORKDIR /root/<APPLICATION_NAME>

# Add wait script to the image
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.9.0/wait ../wait
RUN chmod +x ../wait

# pin to node v16 instead of debian default
# this is the most recent LTS node version as of 2021-11
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
# add chrome source to apt package sources
    curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb [arch=amd64]  http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list && \
# update apt package lists
    apt-get update && \
# install packages
#  - nodejs for npm registry access
#  - less for paging in dev consoles
#  - google-chrome-stable for selenium testing
    apt-get -y install nodejs less google-chrome-stable

# install yarn for package management
RUN npm install -g yarn && \
# set yarn version
    yarn set version berry

# set bundler path
RUN bundle config path /root/<APPLICATION_NAME>/vendor/bundle
