# <APPLICATION_NAME>

- [Introduction](#introduction)
- [Setup](#setup)
- [Dockerization](#dockerization)
- [External Services](#external-services)
  - [CI via GitHub Actions](#ci-via-github-actions)
  - [Heroku Integration](#heroku-integration)
- [Common Tasks](#common-tasks)
  - [Updating Gems and Node Modules](#updating-gems-and-node-modules)
  - [Running Rails Tasks](#running-rails-tasks)
- [Recommended Aliases](#recommended-aliases)

## Introduction

This application was (ostensibly) boostrapped with [MHS's Dockerized Rails bootstrapping script](https://github.com/mhs/docker-rails-bootstrapper)

## Setup

If you just bootstrapped this application, you are effectively done! Don't forget to set up Heroku if desired. Consider the optional steps below if you want to have a better development experience

For those who come after: when this application was bootstrapped its setup script was wrapped by a new one. The modified script creates and configures your Docker environment, and then runs the original script inside a container running Rails. As such, once `bin/setup` has been run the Dockerized application should be ready for use

Here are some suggested, optional steps to make your experience better:

- Fill out `docker_support/docker.bashrc` with aliases, functions, and other nice-to-haves for use within your Rails containers' shells
- [Add aliases to your shell](#recommended-aliases) for common commands that become long-winded when working with dockerized Rails applications

## Dockerization

This application is intended to be used within a Docker container in _all environments_. By default this environment consists of two containers:

- *web*: the Rails application
- *db*: a container running Postgres

Note that some environments - notably any that touch Heroku - will only use the web container, and supply the database by overriding the applications settings using the `DATABASE_URL` environment variable

A fair amount of effort has been put into making sure development of this application is a painless process. In particular:

- Both Dev and CI environments load code, gems, and node modules from Docker volumes, which speeds up package installation (via caching in CI) and should avoid almost all Docker image rebuilds (in Dev)
- In Dev we use files to maintain bash and pry history so you may use up and down to access old entries just like you would in your normal shell
- Dev additionally loads `docker_support/docker.bashrc` when a bash shell starts in a web container; you may add aliases and functions to that file to enable your desired workflow

## External Services

#### CI via GitHub Actions

A CI workflow was installed when the application was bootstrapped, and should "just work". This workflow is configured to run on PRs and whenever anything is merged into the `main` branch. The workflow sets up a Dockerized CI environment and runs a series of sensible, default checks to:

- Ensure [Zeitwerk](https://github.com/fxn/zeitwerk) code loading expectations are met
- Lint Ruby files with [Rubocop](https://docs.rubocop.org/rubocop/index.html)
- Conduct static analysis for Rails app vulnerabilities with [Brakeman](https://brakemanscanner.org/docs/)
- Run all [RSpec](https://rspec.info/documentation/) tests
- Ensure Rails [asset precompilation](https://guides.rubyonrails.org/asset_pipeline.html) can be successfully completed

#### Heroku Integration

*DISCLAIMER: The `app.json` file should handle the bulk of Heroku configuration, but by default uses the Production environment. If this is undesirable, please change the related settings therein or in the corresponding applications within your pipeline*

The bootstrapping script added several files which will help you get set up on Heroku:

- `app.json` contains a template used to configure applications within your pipeline
- `heroku.yml` describes how to build and serve your Dockerized application
- `docker_support/heroku.Dockerfile` describes how to build an image to serve your application

Once the pipeline is created connect it to GitHub and set up as normal

## Common Tasks

#### Updating Gems and Node Modules

Gem and Node Module updates should be run within a web container to ensure that the state of the application's volumes is maintained. To install libraries after changes are made you should run one (or both) of the following:

```sh
docker-compose run web bundle install
# ... or ...
docker-compose run web yarn install
```

#### Running Rails Tasks

Rails tasks (e.g. migrations, DB seeding) should be run within a web container to ensure that the state of the application's volumes is maintained. To run `a:task` you should do the following:


```sh
docker-compose run web bin/rails a:task
# ... or ...
docker-compose run web bundle exec rails a:task
```

## Recommended Aliases

*DISCLAIMER: this is based solely on the author's experience with fully-Dockerized Rails development; YMMV*

Many tasks common to Rails development become very long-winded when working with a fully-Dockerized version of Rails:

- Commands must be prepended with `docker-compose exec web ...` or `docker-compose run web ...` (e.g. gem updates would require `docker-compose run web bundle update [OPTIONS]`)
- Since Rails not directly accessible, its tasks require `... bin/rails ...` or `... bundle exec rails ...`  (e.g. to run migrations we could use `docker-compose run web bin/rails db:migrate`)

This can be rather frustrating, but is easily mitigated by adding aliases to your shell. These are the ones used by the author:

```sh
alias du="docker-compose up"
alias dd="docker-compose down"

alias dr="docker-compose run"
alias de="docker-compose exec"

alias deb="docker-compose exec web bundle"
alias drb="docker-compose run web bundle"

alias dey="docker-compose exec web yarn"
alias dry="docker-compose run web yarn"

alias der="docker-compose exec web bin/rails"
alias drr="docker-compose run web bin/rails"
```

The above would allow e.g. `drb update [OPTIONS]` and `drr db:migrate` - much better!
