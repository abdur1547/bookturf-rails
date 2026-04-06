# Operations

Operations provide a structured way to handle business workflows with built-in validation, error handling, and step-based execution.

## Quick Start

### 1. Create an Operation

```ruby
# app/operations/users/register_operation.rb
module Users
  class RegisterOperation < BaseOperation
    # Define parameter validation
    contract do
      params do
        required(:email).filled(:string)
        required(:password).filled(:string, min_size?: 8)
        required(:first_name).filled(:string)
        required(:last_name).filled(:string)
      end
    end

    def call(params)
      user = User.create(params)
      
      if user.persisted?
        Success(user)
      else
        Failure(user.errors)
      end
    end
  end
end
```

### 2. Call from Controller

```ruby
class UsersController < ApplicationController
  def create
    result = Users::RegisterOperation.call(user_params)

    if result.success?
      render json: result.value, status: :created
    else
      render json: { errors: result.errors_hash }, status: :unprocessable_entity
    end
  end
end
```

## Key Features

### Automatic Validation
Parameters are validated before execution. Invalid params return failure immediately.

### Railway-Oriented Programming
Use `yield` to chain steps. First failure stops execution and returns.

```ruby
def call(params)
  user = yield create_user(params)
  profile = yield create_profile(user)
  yield send_welcome_email(user)
  
  Success(user)
end
```

### Consistent Results
All operations return a `Result` object with:
- `success?` / `failure?` - Check status
- `value` - Get success data
- `errors` / `errors_hash` - Get error details

## Example Operations

See example operations in:
- `app/operations/users/register_operation.rb` - Inline contract validation
- `app/operations/orders/process_order_operation.rb` - External contract, multi-step
- `app/operations/reports/generate_sales_report_operation.rb` - No validation

## External Contracts

For complex validation, create contracts in `app/operations/contracts/`:

```ruby
# app/operations/contracts/orders/process_order_contract.rb
module Orders
  class ProcessOrderContract < Dry::Validation::Contract
    params do
      required(:user_id).filled(:integer)
      required(:items).filled(:array).each do
        hash do
          required(:product_id).filled(:integer)
          required(:quantity).filled(:integer, gt?: 0)
        end
      end
    end
  end
end

# app/operations/orders/process_order_operation.rb
require_relative "../contracts/orders/process_order_contract"

module Orders
  class ProcessOrderOperation < BaseOperation
    contract_class ProcessOrderContract
    
    def call(params)
      # ... implementation
    end
  end
end
```

## When to Use Operations vs Services

**Use Operations:**
- Called directly from controllers
- Complex workflows with multiple steps
- Need parameter validation
- Can fail at multiple points

**Use Services:**
- Reusable business logic
- Shared across operations
- Simple, focused functionality

**Pattern:**
```
Controller → Operation → Services
                ↓
              Result
```

## Documentation

See [doc/OPERATIONS.md](../../doc/OPERATIONS.md) for:
- Comprehensive usage guide
- Validation patterns
- Multi-step execution
- Error handling
- Testing strategies
- Best practices
- Common patterns

## Testing

```ruby
RSpec.describe Users::RegisterOperation do
  it "succeeds with valid params" do
    result = described_class.call(
      email: "user@example.com",
      password: "SecurePass123",
      first_name: "John",
      last_name: "Doe"
    )

    expect(result).to be_success
    expect(result.value).to be_a(User)
  end

  it "fails with invalid email" do
    result = described_class.call(
      email: "invalid",
      password: "SecurePass123",
      first_name: "John",
      last_name: "Doe"
    )

    expect(result).to be_failure
    expect(result.errors_hash).to have_key(:email)
  end
end
```

## Dependencies

- **dry-validation** (~> 1.10) - Parameter validation
- **dry-monads** (~> 1.6) - Railway-oriented programming
