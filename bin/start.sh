#!/usr/bin/env bash

bundle install -j4 --without development test
RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production bundle exec rake assets:precompile
RAILS_ENV=production bundle exec passenger stop --port 4000
RAILS_ENV=production bundle exec passenger start -p 4000 -e production --max-pool-size 2 -d
