FROM ruby:2.7.2-buster

# set up app root
WORKDIR /root/app

# Add wait script to the image
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.7.3/wait ../wait
RUN chmod +x ../wait

# use node LTS, not 10 (Debian default)
RUN curl -sL https://deb.nodesource.com/setup_lts.x | bash - && \
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
RUN bundle config path /root/app/vendor/bundle
