# BaseService Quick Reference

## Basic Usage

```ruby
# Call the service
result = MyService.call(param1, param2, keyword: value)

# Check result
if result.success?
  data = result.data
  # Handle success
else
  error = result.error
  # Handle failure
end
```

## Creating a Service

```ruby
class MyService < BaseService
  # No initialize needed! Params go directly in call
  def call(param1, param2:)
    @param1 = param1
    @param2 = param2
    
    return failure('Error message') unless valid?
    
    # Business logic here
    result = do_something
    
    success(result)
  rescue StandardError => e
    failure(e.message)
  end

  private

  def valid?
    # Validations
  end
end
```

**Key Point:** Parameters are passed directly to the `call` method, eliminating the need for `initialize`!

## Result Object Methods

```ruby
result.success?   # => true/false
result.failure?   # => true/false
result.data       # => returned data (on success)
result.error      # => error message/object (on failure)
```

## Common Patterns

### Validation
```ruby
def call
  return failure('Email required') if @email.blank?
  return failure('Invalid format') unless valid_format?
  # continue...
end
```

### Multiple Errors
```ruby
def call
  errors = []
  errors << 'Error 1' if condition1
  errors << 'Error 2' if condition2
  return failure(errors) if errors.any?
  # continue...
end
```

### Calling Other Services
```ruby
def call
  user_result = CreateUserService.call(email: @email)
  return user_result if user_result.failure?
  
  user = user_result.data
  # continue with user...
end
```

### Transaction Handling
```ruby
def call
  ActiveRecord::Base.transaction do
    step1
    step2
    step3
    success(result)
  end
rescue StandardError => e
  failure(e.message)
end
```

## In Controllers

```ruby
def create
  result = CreateUserService.call(user_params)
  
  if result.success?
    redirect_to result.data, notice: 'Success!'
  else
    flash.now[:alert] = result.error
    render :new
  end
end
```

## In Jobs

```ruby
def perform(user_id)
  result = ProcessUserService.call(user_id: user_id)
  raise result.error if result.failure?
end
```

## Testing

```ruby
RSpec.describe MyService, type: :service do
  describe '.call' do
    context 'with valid params' do
      it 'returns success' do
        result = described_class.call(valid_params)
        
        expect(result).to be_success
        expect(result.data).to eq(expected_data)
      end
    end
    
    context 'with invalid params' do
      it 'returns failure' do
        result = described_class.call(invalid_params)
        
        expect(result).to be_failure
        expect(result.error).to include('Error message')
      end
    end
  end
end
```

## Best Practices

✅ Name with action verbs (CreateUser, SendEmail, CalculateTotal)
✅ Single responsibility per service
✅ Validate inputs early
✅ Always return Result objects
✅ Handle exceptions gracefully
✅ Use private methods for organization
✅ Log errors for debugging

❌ Don't access params/session directly
❌ Don't render/redirect in services
❌ Don't make services too complex
❌ Don't return inconsistent types

## Examples in this Project

- `BaseService` - Base class with Result handling
- `CalculateTotalPriceService` - Calculation example
- `CreateUserService` - Validation & error handling example

See `doc/SERVICE_OBJECTS.md` for full documentation.
