# CI/CD Integration for RSpec

This document provides examples for integrating RSpec into your CI/CD pipeline.

## GitHub Actions

Create `.github/workflows/test.yml`:

```yaml
name: Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    env:
      RAILS_ENV: test
      DATABASE_URL: postgres://postgres:postgres@localhost:5432/test_db

    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.3'
        bundler-cache: true
    
    - name: Install dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y libpq-dev
    
    - name: Setup database
      run: |
        bundle exec rails db:create
        bundle exec rails db:schema:load
    
    - name: Run RSpec
      run: bundle exec rspec
    
    - name: Upload coverage
      uses: actions/upload-artifact@v4
      if: always()
      with:
        name: coverage-report
        path: coverage/
```

## GitLab CI

Create `.gitlab-ci.yml`:

```yaml
image: ruby:3.3

services:
  - postgres:16

variables:
  POSTGRES_DB: test_db
  POSTGRES_USER: postgres
  POSTGRES_PASSWORD: postgres
  DATABASE_URL: "postgresql://postgres:postgres@postgres:5432/test_db"
  RAILS_ENV: test

cache:
  paths:
    - vendor/bundle

before_script:
  - gem install bundler
  - bundle install --jobs $(nproc) --path vendor/bundle
  - bundle exec rails db:create
  - bundle exec rails db:schema:load

test:
  stage: test
  script:
    - bundle exec rspec
  artifacts:
    when: always
    paths:
      - coverage/
    reports:
      junit: tmp/rspec_results.xml
  coverage: '/\(\d+.\d+\%\) covered/'
```

## CircleCI

Create `.circleci/config.yml`:

```yaml
version: 2.1

orbs:
  ruby: circleci/ruby@2.1

jobs:
  test:
    docker:
      - image: cimg/ruby:3.3-node
      - image: cimg/postgres:16.0
        environment:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
    
    environment:
      BUNDLE_JOBS: "3"
      BUNDLE_RETRY: "3"
      RAILS_ENV: test
      DATABASE_URL: postgres://postgres:postgres@localhost:5432/test_db
    
    steps:
      - checkout
      
      - ruby/install-deps
      
      - run:
          name: Wait for DB
          command: dockerize -wait tcp://localhost:5432 -timeout 1m
      
      - run:
          name: Setup database
          command: |
            bundle exec rails db:create
            bundle exec rails db:schema:load
      
      - run:
          name: Run RSpec
          command: bundle exec rspec
      
      - store_test_results:
          path: tmp/rspec_results
      
      - store_artifacts:
          path: coverage

workflows:
  version: 2
  build:
    jobs:
      - test
```

## Code Coverage Reporting

### Coveralls

Add to `Gemfile`:
```ruby
gem 'coveralls_reborn', require: false
```

Update `spec/spec_helper.rb`:
```ruby
if ENV['CI']
  require 'coveralls'
  Coveralls.wear!('rails')
else
  require 'simplecov'
  SimpleCov.start 'rails'
end
```

### Codecov

Add to `.github/workflows/test.yml`:
```yaml
- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v4
  with:
    file: ./coverage/.resultset.json
    fail_ci_if_error: true
```

## Parallel Testing

### Using parallel_tests gem

Add to `Gemfile`:
```ruby
gem 'parallel_tests', group: :test
```

Setup:
```bash
bundle exec rails parallel:setup
```

Run tests:
```bash
bundle exec parallel_rspec spec/
```

In CI (GitHub Actions):
```yaml
- name: Run RSpec in parallel
  run: bundle exec parallel_rspec spec/ -n 4
```

## Test Splitting for Faster CI

### Example with CircleCI

```yaml
- run:
    name: Run RSpec with splitting
    command: |
      circleci tests glob "spec/**/*_spec.rb" | \
      circleci tests split --split-by=timings | \
      xargs bundle exec rspec
```

## Performance Tips for CI

1. **Cache dependencies**:
   - Cache `vendor/bundle` or use `bundler-cache: true`

2. **Cache database schema**:
   - Use `db:schema:load` instead of `db:migrate` in CI

3. **Run tests in parallel**:
   - Use `parallel_tests` gem or CI parallelization

4. **Skip unnecessary specs**:
   - Tag slow specs and skip them for quick feedback
   ```bash
   bundle exec rspec --tag ~slow
   ```

5. **Use faster database strategies**:
   - Configure Database Cleaner for speed in CI

## Example: Fast Feedback Loop

Create separate CI jobs:
```yaml
jobs:
  fast-tests:
    # Run only fast unit tests
    run: bundle exec rspec spec/models spec/lib --tag ~slow
  
  full-tests:
    # Run all tests including slow ones
    run: bundle exec rspec
```

## Notification Integration

### Slack Notifications

Add to GitHub Actions:
```yaml
- name: Slack Notification
  uses: 8398a7/action-slack@v3
  if: always()
  with:
    status: ${{ job.status }}
    text: 'RSpec Test Results'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## Example: Complete GitHub Actions with All Features

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        ruby-version: ['3.2', '3.3']
    
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Ruby ${{ matrix.ruby-version }}
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: ${{ matrix.ruby-version }}
        bundler-cache: true
    
    - name: Setup database
      run: |
        bundle exec rails db:create
        bundle exec rails db:schema:load
    
    - name: Run RuboCop
      run: bundle exec rubocop
    
    - name: Run Brakeman
      run: bundle exec brakeman
    
    - name: Run RSpec
      run: bundle exec rspec --format progress --format RspecJunitFormatter --out tmp/rspec_results.xml
    
    - name: Publish Test Results
      uses: EnricoMi/publish-unit-test-result-action@v2
      if: always()
      with:
        files: tmp/rspec_results.xml
    
    - name: Upload Coverage
      uses: codecov/codecov-action@v4
      with:
        files: ./coverage/.resultset.json
```

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitLab CI Documentation](https://docs.gitlab.com/ee/ci/)
- [CircleCI Documentation](https://circleci.com/docs/)
- [parallel_tests gem](https://github.com/grosser/parallel_tests)
