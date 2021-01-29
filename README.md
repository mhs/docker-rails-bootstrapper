# Dockerized Rails bootstrapping script

This script handles bootstrapping of a Dockerized Rails app which ticks all the usual MHS boxes. In particular it:
- creates a new directory to house the application
- creates a dockerized rails app with that name in that directory
- installs and configures several "must-have" gems
- revises the default Rails setup script to work with the Dockerized environment
- sets up a CI Action using GitHub Actions
- TODO: sets up Heroku review apps
- Pushes an upstream "main" branch to GitHub with a single commit containing the bootstrapped application

To run this script simply enter the following (or an equivalent) into your shell:

```
bash <(curl -s https://raw.githubusercontent.com/mhs/docker-rails-bootstrapper/main/bootstrap.sh)
```

*NOTE:* this script requires input - you must ensure your keyboard input is connected to STDIN for this to work correctly!
