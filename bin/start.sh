#!/usr/bin/env bash

bundle install -j4 --without development test
RAILS_ENV=production rake db:migrate
RAILS_ENV=production rake assets:precompile
RAILS_ENV=production bundle exec passenger stop
RAILS_ENV=production bundle exec passenger start -p 4000 -e production -d
