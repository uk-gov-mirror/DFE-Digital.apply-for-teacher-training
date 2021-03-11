web: SERVICE_TYPE=web bundle exec puma -C config/puma.rb
worker: SERVICE_TYPE=worker bundle exec sidekiq -c 5 -C config/sidekiq.yml
