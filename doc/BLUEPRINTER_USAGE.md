# Blueprinter Usage Guide

## Overview

Blueprinter is a fast, declarative JSON serializer for Ruby APIs. It replaces jbuilder in this application for better performance and cleaner API response formatting.

## Basic Usage

### Simple Rendering

```ruby
# In a controller
def show
  user = User.find(params[:id])
  render json: UserBlueprint.render(user)
end

# Output:
# {
#   "id": 1,
#   "email": "user@example.com",
#   "name": "John Doe"
# }
```

### Collection Rendering

```ruby
def index
  users = User.all
  render json: UserBlueprint.render(users)
end

# With root key
render json: UserBlueprint.render(users, root: :users)

# Output:
# {
#   "users": [
#     {"id": 1, "email": "user@example.com", "name": "John Doe"},
#     {"id": 2, "email": "jane@example.com", "name": "Jane Smith"}
#   ]
# }
```

## Views

Blueprinter supports multiple views for different contexts:

### Default View

```ruby
UserBlueprint.render(user)
# Returns: id, email, name
```

### Detailed View

```ruby
UserBlueprint.render(user, view: :detailed)
# Returns: id, email, name, created_at, updated_at, sign_in_count, etc.
```

### Profile View

```ruby
UserBlueprint.render(user, view: :profile)
# Returns: name, email, avatar_url, created_at, member_since
```

### With Token (for authentication)

```ruby
UserBlueprint.render(user, view: :with_token, token: jwt_token)
# Returns: id, email, name, token, token_type, expires_in
```

### Minimal View

```ruby
UserBlueprint.render(user, view: :minimal)
# Returns: id, name (for dropdowns, etc.)
```

## Creating Blueprints

### Basic Blueprint

```ruby
# app/blueprints/post_blueprint.rb
class PostBlueprint < BaseBlueprint
  identifier :id
  
  fields :title, :body, :published
  timestamps  # Adds created_at, updated_at
end
```

### With Associations

```ruby
class PostBlueprint < BaseBlueprint
  identifier :id
  fields :title, :body
  
  # Belongs to association
  association :author, blueprint: UserBlueprint
  
  # Has many association
  association :comments, blueprint: CommentBlueprint
end
```

### With Custom Fields

```ruby
class UserBlueprint < BaseBlueprint
  identifier :id
  fields :email, :name
  
  # Computed field
  field :full_name do |user|
    "#{user.first_name} #{user.last_name}"
  end
  
  # Field with options
  field :token do |user, options|
    options[:token]
  end
  
  # Renamed field
  field :sign_in_count, name: :total_logins
end
```

### With Conditional Fields

```ruby
class UserBlueprint < BaseBlueprint
  identifier :id
  fields :email, :name
  
  # Only include if condition is met
  field :admin_notes, if: ->(user, options) { options[:current_user]&.admin? }
  
  # Exclude if condition is met
  field :private_data, unless: ->(user, options) { options[:public_view] }
end
```

### With Multiple Views

```ruby
class ProductBlueprint < BaseBlueprint
  identifier :id
  fields :name, :price
  
  view :detailed do
    fields :description, :stock_quantity
    timestamps
  end
  
  view :admin do
    fields :cost_price, :supplier_id
    association :supplier, blueprint: SupplierBlueprint
  end
end

# Usage
ProductBlueprint.render(product, view: :detailed)
ProductBlueprint.render(product, view: :admin)
```

## Controller Examples

### Basic CRUD

```ruby
class Api::V1::UsersController < Api::V1::BaseController
  def index
    users = User.all
    render json: UserBlueprint.render(users, root: :users)
  end
  
  def show
    user = User.find(params[:id])
    render json: UserBlueprint.render(user, view: :detailed)
  end
  
  def create
    user = User.new(user_params)
    
    if user.save
      render json: UserBlueprint.render(user), status: :created
    else
      render json: ErrorBlueprint.render_as_hash(
        message: "Validation failed",
        errors: user.errors,
        status: 422
      ), status: :unprocessable_entity
    end
  end
end
```

### With Authentication

```ruby
class Api::V1::AuthController < Api::V1::BaseController
  def login
    result = Auth::LoginOperation.call(email: params[:email], password: params[:password])
    
    if result.success?
      render json: UserBlueprint.render(
        result.value[:user],
        view: :with_token,
        token: result.value[:token],
        expires_in: 86400
      )
    else
      render json: ErrorBlueprint.render_as_hash(
        message: "Invalid credentials",
        status: 401
      ), status: :unauthorized
    end
  end
end
```

### With Pagination

```ruby
def index
  users = User.page(params[:page]).per(20)
  
  render json: {
    users: UserBlueprint.render_as_hash(users),
    pagination: {
      current_page: users.current_page,
      total_pages: users.total_pages,
      total_count: users.total_count
    }
  }
end
```

## Error Responses

```ruby
# Validation errors
render json: ErrorBlueprint.render_as_hash(
  message: "Validation failed",
  errors: record.errors.full_messages,
  status: 422
), status: :unprocessable_entity

# Not found
render json: ErrorBlueprint.render_as_hash(
  message: "Resource not found",
  status: 404
), status: :not_found

# Unauthorized
render json: ErrorBlueprint.render_as_hash(
  message: "Authentication required",
  status: 401
), status: :unauthorized
```

## Advanced Features

### Custom Transformers

```ruby
# In BaseBlueprint or individual blueprint
class UppercaseTransformer < Blueprinter::Transformer
  def transform(value, _object, _options)
    value&.upcase
  end
end

class UserBlueprint < BaseBlueprint
  identifier :id
  field :name, transform: UppercaseTransformer
end
```

### Extractor Classes

```ruby
class FullNameExtractor < Blueprinter::Extractor
  def extract(field_name, object, local_options, options)
    "#{object.first_name} #{object.last_name}"
  end
end

class UserBlueprint < BaseBlueprint
  field :full_name, extractor: FullNameExtractor
end
```

### Meta Fields

```ruby
class UserBlueprint < BaseBlueprint
  identifier :id
  fields :email, :name
  
  field :meta do |user, options|
    {
      request_id: options[:request_id],
      timestamp: Time.current.iso8601
    }
  end
end
```

## Testing Blueprints

```ruby
# spec/blueprints/user_blueprint_spec.rb
require 'rails_helper'

RSpec.describe UserBlueprint do
  let(:user) { create(:user, email: 'test@example.com', name: 'Test User') }
  
  describe 'default view' do
    subject { described_class.render_as_hash(user) }
    
    it 'includes basic fields' do
      expect(subject).to include(
        id: user.id,
        email: 'test@example.com',
        name: 'Test User'
      )
    end
    
    it 'does not include timestamps' do
      expect(subject).not_to have_key(:created_at)
      expect(subject).not_to have_key(:updated_at)
    end
  end
  
  describe 'detailed view' do
    subject { described_class.render_as_hash(user, view: :detailed) }
    
    it 'includes timestamps' do
      expect(subject).to have_key(:created_at)
      expect(subject).to have_key(:updated_at)
    end
  end
  
  describe 'with_token view' do
    let(:token) { 'jwt.token.here' }
    subject { described_class.render_as_hash(user, view: :with_token, token: token) }
    
    it 'includes token' do
      expect(subject[:token]).to eq(token)
      expect(subject[:token_type]).to eq('Bearer')
    end
  end
end
```

## Performance Tips

### Use `render_as_hash` for Better Performance

```ruby
# When you need a hash (faster)
UserBlueprint.render_as_hash(user)

# When you need JSON string
UserBlueprint.render(user)
```

### Preload Associations

```ruby
# Avoid N+1 queries
users = User.includes(:posts, :comments)
UserBlueprint.render(users)
```

### Use Minimal Views

```ruby
# For dropdowns and selects, use minimal view
UserBlueprint.render(users, view: :minimal)
# Returns only id and name
```

## Common Patterns

### API Response Helper

```ruby
# app/controllers/concerns/api_response.rb
module ApiResponse
  def render_success(resource, blueprint, **options)
    render json: blueprint.render(resource, **options)
  end
  
  def render_error(message, status: 422, errors: nil)
    render json: ErrorBlueprint.render_as_hash(
      message: message,
      errors: errors,
      status: status
    ), status: status
  end
end

# Usage in controller
class Api::V1::UsersController < Api::V1::BaseController
  include ApiResponse
  
  def show
    user = User.find(params[:id])
    render_success(user, UserBlueprint, view: :detailed)
  end
  
  def create
    user = User.new(user_params)
    
    if user.save
      render_success(user, UserBlueprint)
    else
      render_error("Validation failed", errors: user.errors)
    end
  end
end
```

## Available Blueprints

This application includes:

- **BaseBlueprint** - Base class with common functionality
- **UserBlueprint** - User serialization with multiple views
- **OrderBlueprint** - Order serialization
- **ErrorBlueprint** - Error response formatting

## Resources

- [Blueprinter GitHub](https://github.com/procore/blueprinter)
- [Blueprinter Wiki](https://github.com/procore/blueprinter/wiki)

## Migration from Jbuilder

### Before (Jbuilder)

```ruby
# app/views/users/show.json.jbuilder
json.id @user.id
json.email @user.email
json.name @user.name
json.created_at @user.created_at

# Controller
def show
  @user = User.find(params[:id])
  # Implicit rendering of view
end
```

### After (Blueprinter)

```ruby
# app/blueprints/user_blueprint.rb
class UserBlueprint < BaseBlueprint
  identifier :id
  fields :email, :name, :created_at
end

# Controller
def show
  user = User.find(params[:id])
  render json: UserBlueprint.render(user)
end
```

**Benefits:**
- ✅ No view files needed
- ✅ Faster rendering
- ✅ Easier testing
- ✅ Better reusability
- ✅ Type safety
