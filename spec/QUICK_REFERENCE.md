# RSpec Quick Reference

## Running Tests
```bash
bundle exec rspec                    # Run all specs
bundle exec rspec spec/models        # Run specific directory
bundle exec rspec spec/models/user_spec.rb       # Run specific file
bundle exec rspec spec/models/user_spec.rb:10    # Run specific line

# Rake tasks
rake spec:models                     # Run model specs
rake spec:requests                   # Run request specs
rake spec:system                     # Run system specs
rake spec:coverage_open             # Run with coverage and open report
rake spec:failed                    # Run only failed specs
```

## Common Matchers
```ruby
# Equality
expect(actual).to eq(expected)
expect(actual).to be(expected)       # Same object
expect(actual).to eql(expected)      # Same value

# Truthiness
expect(actual).to be_truthy
expect(actual).to be_falsey
expect(actual).to be_nil

# Comparisons
expect(actual).to be > expected
expect(actual).to be >= expected
expect(actual).to be < expected
expect(actual).to be <= expected
expect(actual).to be_between(min, max)

# Types/Classes
expect(actual).to be_a(String)
expect(actual).to be_an_instance_of(String)
expect(actual).to respond_to(:method_name)

# Collections
expect(array).to include(item)
expect(array).to match_array([1, 2, 3])
expect(array).to contain_exactly(1, 2, 3)
expect(hash).to have_key(:key)
expect(hash).to have_value(value)

# Strings
expect(string).to start_with('prefix')
expect(string).to end_with('suffix')
expect(string).to match(/regex/)

# Errors
expect { block }.to raise_error(ErrorClass)
expect { block }.to raise_error(ErrorClass, 'message')
expect { block }.not_to raise_error

# Changes
expect { block }.to change(Model, :count).by(1)
expect { block }.to change { object.attribute }.from(old).to(new)
```

## Shoulda Matchers
```ruby
# Model validations
it { should validate_presence_of(:email) }
it { should validate_uniqueness_of(:email) }
it { should validate_length_of(:password).is_at_least(8) }
it { should validate_numericality_of(:age) }
it { should validate_inclusion_of(:role).in_array(['admin', 'user']) }

# Associations
it { should belong_to(:user) }
it { should have_many(:posts) }
it { should have_one(:profile) }
it { should have_and_belong_to_many(:tags) }

# Database
it { should have_db_column(:email).of_type(:string) }
it { should have_db_index(:email) }
```

## FactoryBot
```ruby
# Creating records
user = create(:user)                          # Save to database
user = build(:user)                           # Don't save
attrs = attributes_for(:user)                 # Hash of attributes
users = create_list(:user, 5)                 # Create 5 users

# With overrides
user = create(:user, email: 'custom@example.com')

# With traits
user = create(:user, :admin)
user = create(:user, :admin, :with_posts)

# Associations
post = create(:post, user: create(:user))
post = create(:post)  # If factory has association defined
```

## Request Specs
```ruby
# HTTP verbs
get '/users'
post '/users', params: { user: attributes }
patch '/users/1', params: { user: attributes }
put '/users/1', params: { user: attributes }
delete '/users/1'

# Response expectations
expect(response).to have_http_status(:success)      # 200
expect(response).to have_http_status(:created)      # 201
expect(response).to have_http_status(:redirect)     # 3xx
expect(response).to have_http_status(:not_found)    # 404
expect(response).to have_http_status(200)

expect(response).to render_template(:index)
expect(response).to redirect_to(users_path)

# JSON responses
json = JSON.parse(response.body)
expect(json['email']).to eq('test@example.com')
```

## System Specs (Capybara)
```ruby
# Navigation
visit root_path
click_link 'Sign Up'
click_button 'Submit'
click_on 'Link or Button'

# Forms
fill_in 'Email', with: 'test@example.com'
check 'Remember me'
uncheck 'Remember me'
choose 'Option 1'
select 'Option', from: 'Select Box'
attach_file 'File', '/path/to/file'

# Expectations
expect(page).to have_content('Text')
expect(page).to have_selector('css selector')
expect(page).to have_link('Link Text')
expect(page).to have_button('Button Text')
expect(page).to have_field('Field Label')
expect(page).to have_current_path(root_path)

# Waiting for asynchronous content
expect(page).to have_content('Text', wait: 5)
```

## Let and Before
```ruby
# let - lazy evaluation, memoized
let(:user) { create(:user) }

# let! - evaluated immediately
let!(:user) { create(:user) }

# before - run before each example
before do
  @user = create(:user)
end

# before(:suite) - run once before all specs
before(:suite) do
  # Setup code
end
```

## Contexts and Shared Examples
```ruby
# Contexts
context 'when user is admin' do
  let(:user) { create(:user, :admin) }
  
  it 'allows access' do
    # ...
  end
end

context 'when user is regular' do
  let(:user) { create(:user) }
  
  it 'denies access' do
    # ...
  end
end

# Shared examples
shared_examples 'a timestamped model' do
  it { should respond_to(:created_at) }
  it { should respond_to(:updated_at) }
end

RSpec.describe User, type: :model do
  it_behaves_like 'a timestamped model'
end
```

## Metadata and Tags
```ruby
# Skip examples
it 'does something', skip: true do
  # ...
end

# Pending examples
it 'does something' do
  pending 'Not implemented yet'
  # ...
end

# Focus on specific examples
it 'does something', focus: true do
  # ...
end

# Tag examples
it 'slow test', :slow do
  # ...
end

# Run tagged specs
bundle exec rspec --tag slow
bundle exec rspec --tag ~slow  # Exclude slow
```
