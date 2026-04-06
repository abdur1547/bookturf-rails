# RSpec Testing Setup

This Rails project uses RSpec as the testing framework with the following gems and best practices.

## Installed Gems

### Testing Framework
- **rspec-rails** (~> 7.1) - RSpec testing framework for Rails
- **factory_bot_rails** (~> 6.4) - Fixtures replacement with a straightforward definition syntax
- **faker** (~> 3.5) - Library for generating fake data

### Testing Tools
- **shoulda-matchers** (~> 6.4) - Simple one-liner tests for common Rails functionality
- **database_cleaner-active_record** (~> 2.2) - Strategies for cleaning databases between tests
- **simplecov** (~> 0.22) - Code coverage analysis tool
- **capybara** - System/feature testing framework
- **selenium-webdriver** - Browser automation for system tests

## Directory Structure

```
spec/
├── support/              # Configuration files
│   ├── factory_bot.rb
│   ├── shoulda_matchers.rb
│   ├── database_cleaner.rb
│   └── capybara.rb
├── models/              # Model specs
├── controllers/         # Controller specs (legacy, prefer request specs)
├── requests/            # Request specs (recommended)
├── routing/             # Routing specs
├── system/              # System/feature specs
├── factories/           # FactoryBot factories
├── fixtures/            # Test fixtures
├── rails_helper.rb      # Rails-specific test configuration
└── spec_helper.rb       # General RSpec configuration
```

## Running Tests

```bash
# Run all specs
bundle exec rspec

# Run specific spec file
bundle exec rspec spec/models/user_spec.rb

# Run specific example
bundle exec rspec spec/models/user_spec.rb:10

# Run specs by type
bundle exec rspec spec/models
bundle exec rspec spec/requests
bundle exec rspec spec/system

# Run with documentation format
bundle exec rspec --format documentation

# Run only failed specs from last run
bundle exec rspec --only-failures

# Run specs tagged with focus
bundle exec rspec --tag focus
```

## Writing Tests

### Model Specs

```ruby
# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  # Use shoulda-matchers for associations and validations
  it { should validate_presence_of(:email) }
  it { should validate_uniqueness_of(:email) }
  it { should have_many(:posts) }

  # Custom tests
  describe '#full_name' do
    it 'returns first and last name' do
      user = create(:user, first_name: 'John', last_name: 'Doe')
      expect(user.full_name).to eq('John Doe')
    end
  end
end
```

### Request Specs (Recommended over Controller Specs)

```ruby
# spec/requests/users_spec.rb
require 'rails_helper'

RSpec.describe 'Users', type: :request do
  describe 'GET /users' do
    it 'returns success' do
      get users_path
      expect(response).to have_http_status(:success)
    end

    it 'renders the index template' do
      get users_path
      expect(response).to render_template(:index)
    end
  end

  describe 'POST /users' do
    context 'with valid parameters' do
      let(:valid_attributes) { attributes_for(:user) }

      it 'creates a new user' do
        expect {
          post users_path, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end
    end
  end
end
```

### System Specs (Feature Tests)

```ruby
# spec/system/users_spec.rb
require 'rails_helper'

RSpec.describe 'Users', type: :system do
  it 'creates a new user' do
    visit new_user_path
    
    fill_in 'Email', with: 'test@example.com'
    fill_in 'Password', with: 'password123'
    
    click_button 'Sign Up'
    
    expect(page).to have_content('User was successfully created')
  end

  # For JavaScript tests
  it 'filters users dynamically', js: true do
    create(:user, name: 'John Doe')
    create(:user, name: 'Jane Smith')
    
    visit users_path
    fill_in 'Search', with: 'John'
    
    expect(page).to have_content('John Doe')
    expect(page).not_to have_content('Jane Smith')
  end
end
```

### Using FactoryBot

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    
    # Traits
    trait :admin do
      role { 'admin' }
    end
    
    trait :with_posts do
      after(:create) do |user|
        create_list(:post, 3, user: user)
      end
    end
  end
end

# Usage in specs
create(:user)                    # Creates and saves
build(:user)                     # Builds without saving
attributes_for(:user)            # Returns hash of attributes
create(:user, :admin)            # Using traits
create(:user, :with_posts)       # User with 3 posts
create_list(:user, 5)            # Creates 5 users
```

## Code Coverage

SimpleCov generates code coverage reports automatically. After running specs, open `coverage/index.html` to view the report.

```bash
bundle exec rspec
open coverage/index.html  # macOS
xdg-open coverage/index.html  # Linux
```

## Configuration

### Generator Configuration

When you generate a new model, controller, or other Rails resource, RSpec specs will be automatically generated:

```bash
rails generate model User email:string
# Creates:
#   spec/models/user_spec.rb
#   spec/factories/users.rb

rails generate request Users
# Creates:
#   spec/requests/users_spec.rb
```

### Test Database

The test database is automatically managed by RSpec. To reset:

```bash
RAILS_ENV=test bundle exec rails db:reset
RAILS_ENV=test bundle exec rails db:migrate
```

## Best Practices

1. **Use request specs over controller specs** - Controller specs test in isolation, request specs test the full stack
2. **Keep specs focused** - One expectation per example when possible
3. **Use factories over fixtures** - More flexible and easier to maintain
4. **Use `let` and `let!` for shared data** - Lazy-loaded and memoized
5. **Use descriptive context blocks** - `context 'when user is admin'`
6. **Tag slow specs** - Use `:slow` tag and filter when needed
7. **Use `aggregate_failures`** - Group related expectations
8. **Mock external services** - Use VCR or WebMock for HTTP calls
9. **Test edge cases and failures** - Not just the happy path
10. **Keep system specs minimal** - They're slower than request specs

## Useful Commands

```bash
# Generate binstub for rspec
bundle binstubs rspec-core

# Run with binstub (faster)
bin/rspec

# Parallel test execution (add gem 'parallel_tests')
bundle exec parallel_rspec spec/

# Profile slow tests
bundle exec rspec --profile 10
```

## Resources

- [RSpec Rails Documentation](https://rspec.info/features/7-1/rspec-rails/)
- [Better Specs](https://www.betterspecs.org/)
- [FactoryBot Documentation](https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md)
- [Shoulda Matchers](https://matchers.shoulda.io/)
- [Capybara Documentation](https://github.com/teamcapybara/capybara)
