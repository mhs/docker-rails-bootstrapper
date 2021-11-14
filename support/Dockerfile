FROM ruby:2.7.2-buster

# set up app root
WORKDIR /root/<APPLICATION_NAME>

# Add wait script to the image
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait ../wait
RUN chmod +x ../wait

# pin to node v16 instead of debian default
# this is the most recent LTS node version as of 2021-11
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
# add yarn source to apt package sources
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
# add chrome source to apt package sources
    curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb [arch=amd64]  http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list && \
# update apt package lists
    apt-get update && \
# install packages
#  - nodejs for npm registry access
#  - yarn for js package management
#  - less for paging in dev consoles
#  - google-chrome-stable for selenium testing
    apt-get -y install nodejs yarn less google-chrome-stable

# set bundler path
RUN bundle config path /root/<APPLICATION_NAME>/vendor/bundle
