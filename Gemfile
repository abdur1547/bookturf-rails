source "https://rubygems.org"

gem "rails", "~> 8.1.3"

# DB
gem "pg", "~> 1.6"

# Web server
gem "puma", ">= 5.0"

# Assets
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

# JSON
gem "blueprinter"
gem "oj"

# CORS support
gem "rack-cors", "~> 3.0"

# HAML
gem "haml-rails", "~> 3.0"
gem "haml", "~> 7.2"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "mission_control-jobs"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# Dry gems for operations pattern
gem "dry-validation", "~> 1.10"
gem "dry-monads", "~> 1.6"

# Simple, Heroku-friendly Rails app configuration using ENV and a single YAML file
gem "figaro"

# Authentication (JWT for API endpoints)
gem "jwt", "~> 3.1"

gem "pagy", "~> 43.4"

# Authorization
gem "pundit", "~> 2.4"

# Activity tracking
gem "public_activity", "~> 3.0"

# API Documentation
gem "apipie-rails", "~> 1.4"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.6"
end

group :development do
  gem "web-console"
  gem "html2haml"
  gem "better_errors"
  gem "binding_of_caller"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers", "~> 7.0"
  gem "database_cleaner-active_record", "~> 2.2"
  gem "simplecov", "~> 0.22", require: false
  gem "json_matchers"
end
