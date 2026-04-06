# Operations Pattern

## Overview

Operations provide a structured, consistent way to handle business logic in Rails applications. They sit between controllers and services, orchestrating complex workflows with built-in validation, error handling, and step-based execution.

### Key Benefits

- **Automatic Parameter Validation**: Using dry-validation for robust schema validation
- **Railway-Oriented Programming**: Using dry-monads for predictable error handling
- **Early Returns**: Failed steps immediately stop execution and return failure
- **Consistent API**: All operations return a standard Result object
- **Testability**: Easy to test with clear inputs and outputs
- **Service Integration**: Operations can delegate common logic to Services

### When to Use Operations vs Services

**Use Operations when:**
- Called directly from controllers
- Logic is complex and needs multiple steps
- You need parameter validation before execution
- You want to split complex logic into smaller steps
- The workflow can fail at multiple points

**Use Services when:**
- You have reusable business logic
- Multiple operations need the same functionality
- Logic is relatively simple and focused on one thing
- You don't need multi-step orchestration

## Architecture

```
Controller → Operation → Services
                ↓
              Result
```

### Directory Structure

```
app/
  operations/
    base_operation.rb           # Base class for all operations
    contracts/                  # External validation contracts
      orders/
        process_order_contract.rb
      users/
        register_contract.rb
    orders/
      process_order_operation.rb
      cancel_order_operation.rb
    users/
      register_operation.rb
      update_profile_operation.rb
    reports/
      generate_sales_report_operation.rb
```

## Basic Usage

### Simple Operation with Inline Contract

```ruby
class Users::RegisterOperation < BaseOperation
  # Define validation inline
  contract do
    params do
      required(:email).filled(:string)
      required(:password).filled(:string, min_size?: 8)
      required(:first_name).filled(:string)
      required(:last_name).filled(:string)
    end

    rule(:email) do
      unless value.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
        key.failure("must be a valid email address")
      end
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
```

**Usage in Controller:**

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

  private

  def user_params
    params.require(:user).permit(:email, :password, :first_name, :last_name)
  end
end
```

### Operation with External Contract

**Contract File:**

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
          required(:price).filled(:float, gt?: 0)
        end
      end
      required(:payment_method).filled(:string, included_in?: %w[credit_card paypal stripe])
      optional(:shipping_address).maybe(:hash) do
        required(:street).filled(:string)
        required(:city).filled(:string)
        required(:state).filled(:string)
        required(:zip_code).filled(:string)
      end
    end

    rule(:items) do
      if value.is_a?(Array) && value.empty?
        key.failure("must contain at least one item")
      end
    end
  end
end
```

**Operation File:**

```ruby
# app/operations/orders/process_order_operation.rb
require_relative "../contracts/orders/process_order_contract"

module Orders
  class ProcessOrderOperation < BaseOperation
    include Dry::Monads[:result, :do]

    # Use external contract
    contract_class ProcessOrderContract

    def call(params)
      # Each step returns Success or Failure
      # yield unwraps Success, or returns Failure immediately
      subtotal = yield calculate_subtotal(params[:items])
      discount = yield apply_coupon(params[:coupon_code], subtotal)
      total = subtotal - discount

      payment_result = yield process_payment(params[:payment_method], total)
      inventory_result = yield update_inventory(params[:items])
      order = yield create_order(params, total, payment_result)

      Success(order)
    end

    private

    def calculate_subtotal(items)
      total = items.sum { |item| item[:quantity] * item[:price] }
      Success(total)
    rescue StandardError => e
      Failure("Failed to calculate subtotal: #{e.message}")
    end

    def process_payment(payment_method, amount)
      # Delegate to service for common payment logic
      result = PaymentService.call(method: payment_method, amount: amount)

      if result.success?
        Success(result.value)
      else
        Failure("Payment failed: #{result.errors}")
      end
    end

    # ... other step methods
  end
end
```

### Operation Without Validation

For operations that don't need parameter validation:

```ruby
class Reports::GenerateSalesReportOperation < BaseOperation
  # No contract - parameters passed directly to call

  def call(params)
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])

    return Failure("Invalid date range") if start_date > end_date

    report_data = yield fetch_sales_data(start_date, end_date)
    summary = yield calculate_summary(report_data)

    Success(summary)
  end

  private

  def fetch_sales_data(start_date, end_date)
    data = Order.where(created_at: start_date..end_date)
    Success(data)
  rescue StandardError => e
    Failure("Failed to fetch data: #{e.message}")
  end

  def calculate_summary(data)
    # ... calculation logic
    Success(summary)
  end
end
```

## Step-Based Execution

### Do Notation

The `do` notation (from dry-monads) allows clean, readable multi-step operations:

```ruby
class ComplexOperation < BaseOperation
  include Dry::Monads[:result, :do]

  def call(params)
    # Each yield unwraps a Success or returns Failure immediately
    validated_data = yield validate_data(params)
    processed_data = yield process_data(validated_data)
    saved_result = yield save_data(processed_data)
    notification = yield send_notification(saved_result)

    Success(saved_result)
  end

  private

  def validate_data(params)
    # Return Success or Failure
    params[:amount] > 0 ? Success(params) : Failure("Invalid amount")
  end

  def process_data(data)
    # Each step processes and passes data to next step
    processed = data.merge(processed_at: Time.current)
    Success(processed)
  end

  def save_data(data)
    record = Model.create(data)
    record.persisted? ? Success(record) : Failure(record.errors)
  end

  def send_notification(record)
    # Even if notification fails, we might want to continue
    NotificationService.call(record: record)
    Success(true)
  rescue StandardError => e
    # Log error but don't fail the operation
    Rails.logger.error("Notification failed: #{e.message}")
    Success(false)
  end
end
```

### Without Do Notation

For simpler operations, you can use Success/Failure directly:

```ruby
class SimpleOperation < BaseOperation
  def call(params)
    if valid?(params)
      result = perform_action(params)
      Success(result)
    else
      Failure("Invalid parameters")
    end
  end

  private

  def valid?(params)
    params[:value].present?
  end

  def perform_action(params)
    # ... business logic
    { result: "success" }
  end
end
```

## Result Object API

All operations return a `BaseOperation::Result` object with a consistent interface:

### Success Results

```ruby
result = MyOperation.call(params)

result.success?        # => true
result.failure?        # => false
result.value          # => the success value
result.value!         # => the success value (same as .value for success)
result.errors         # => nil
result.errors_hash    # => {}
```

### Failure Results

```ruby
result = MyOperation.call(invalid_params)

result.success?        # => false
result.failure?        # => true
result.value          # => nil
result.value!         # => raises RuntimeError
result.errors         # => error data (string, hash, or validation result)
result.errors_hash    # => normalized error hash
```

### Error Hash Formats

```ruby
# String error
Failure("Something went wrong")
result.errors_hash # => { base: ["Something went wrong"] }

# Hash error
Failure({ email: ["is invalid"], name: ["can't be blank"] })
result.errors_hash # => { email: ["is invalid"], name: ["can't be blank"] }

# Validation result (automatic from dry-validation)
# When contract fails
result.errors_hash # => { email: ["must be a valid email"], password: ["is too short"] }
```

## Validation with Dry-Validation

### Basic Types

```ruby
contract do
  params do
    required(:name).filled(:string)
    required(:age).filled(:integer)
    required(:email).filled(:string)
    optional(:phone).maybe(:string)
  end
end
```

### Type Predicates

```ruby
contract do
  params do
    required(:age).filled(:integer, gt?: 18)         # Greater than 18
    required(:score).filled(:integer, gteq?: 0)      # Greater than or equal to 0
    required(:quantity).filled(:integer, lt?: 100)   # Less than 100
    required(:price).filled(:float, gt?: 0)          # Positive float
    required(:email).filled(:string, min_size?: 5)   # Minimum length
    required(:status).filled(:string, included_in?: %w[active inactive])
  end
end
```

### Nested Structures

```ruby
contract do
  params do
    required(:user).hash do
      required(:name).filled(:string)
      required(:email).filled(:string)
      optional(:address).hash do
        required(:street).filled(:string)
        required(:city).filled(:string)
        optional(:zip).maybe(:string)
      end
    end
  end
end
```

### Arrays and Each

```ruby
contract do
  params do
    required(:items).filled(:array).each do
      hash do
        required(:product_id).filled(:integer)
        required(:quantity).filled(:integer, gt?: 0)
      end
    end
  end
end
```

### Custom Rules

```ruby
contract do
  params do
    required(:email).filled(:string)
    required(:password).filled(:string)
    required(:password_confirmation).filled(:string)
  end

  rule(:email) do
    unless value.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      key.failure("must be a valid email address")
    end
  end

  rule(:password, :password_confirmation) do
    if values[:password] != values[:password_confirmation]
      key.failure("passwords must match")
    end
  end

  rule(:password) do
    unless value.match?(/[A-Z]/) && value.match?(/[a-z]/) && value.match?(/[0-9]/)
      key.failure("must contain uppercase, lowercase, and number")
    end
  end
end
```

### Cross-Field Validation

```ruby
contract do
  params do
    required(:start_date).filled(:date)
    required(:end_date).filled(:date)
  end

  rule(:start_date, :end_date) do
    if values[:start_date] > values[:end_date]
      key(:end_date).failure("must be after start date")
    end
  end
end
```

## Integration with Services

Operations orchestrate workflows; Services encapsulate reusable logic:

```ruby
class Orders::ProcessOrderOperation < BaseOperation
  include Dry::Monads[:result, :do]

  contract_class ProcessOrderContract

  def call(params)
    # Use service for common payment logic
    payment_result = yield process_payment(params)

    # Use service for inventory management
    inventory_result = yield update_inventory(params[:items])

    # Use service for notification
    notification_result = yield send_notification(params[:user_id])

    order = create_order(params, payment_result, inventory_result)
    Success(order)
  end

  private

  def process_payment(params)
    # Delegate to PaymentService
    result = PaymentService.call(
      method: params[:payment_method],
      amount: params[:amount]
    )

    result.success? ? Success(result.value) : Failure(result.errors)
  end

  def update_inventory(items)
    # Delegate to InventoryService
    result = InventoryService.call(items: items)

    result.success? ? Success(result.value) : Failure(result.errors)
  end

  def send_notification(user_id)
    # Delegate to NotificationService
    result = NotificationService.call(
      user_id: user_id,
      message: "Order confirmed"
    )

    # Even if notification fails, don't fail the whole operation
    Success(true)
  rescue StandardError => e
    Rails.logger.warn("Notification failed: #{e.message}")
    Success(false)
  end
end
```

## Error Handling

### Automatic Exception Handling

BaseOperation automatically catches unhandled exceptions:

```ruby
class RiskyOperation < BaseOperation
  def call(params)
    # If this raises an exception, it's automatically caught
    result = ExternalAPI.call(params)
    Success(result)
  end
end

result = RiskyOperation.call(params)
result.failure? # => true if exception occurred
result.errors   # => { error: "exception message", exception: <Exception object> }
```

### Explicit Error Handling

```ruby
class SafeOperation < BaseOperation
  def call(params)
    begin
      result = dangerous_operation(params)
      Success(result)
    rescue SpecificError => e
      Failure("Specific error: #{e.message}")
    rescue StandardError => e
      Rails.logger.error("Unexpected error: #{e.message}")
      Failure("An unexpected error occurred")
    end
  end
end
```

### Early Returns

```ruby
class ValidationHeavyOperation < BaseOperation
  def call(params)
    return Failure("User not found") unless user_exists?(params[:user_id])
    return Failure("Insufficient funds") unless has_funds?(params[:amount])
    return Failure("Invalid status") unless valid_status?(params[:status])

    # All validations passed, proceed with operation
    Success(perform_operation(params))
  end
end
```

## Testing Operations

### Basic Test Structure

```ruby
RSpec.describe Users::RegisterOperation do
  describe ".call" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          email: "user@example.com",
          password: "SecurePass123",
          first_name: "John",
          last_name: "Doe"
        }
      end

      it "returns success" do
        result = described_class.call(valid_params)

        expect(result).to be_success
        expect(result.value).to be_a(User)
        expect(result.value.email).to eq("user@example.com")
      end
    end

    context "with invalid parameters" do
      it "fails when email is missing" do
        result = described_class.call(
          password: "SecurePass123",
          first_name: "John",
          last_name: "Doe"
        )

        expect(result).to be_failure
        expect(result.errors_hash).to have_key(:email)
      end

      it "fails when email format is invalid" do
        result = described_class.call(
          email: "not-an-email",
          password: "SecurePass123",
          first_name: "John",
          last_name: "Doe"
        )

        expect(result).to be_failure
        expect(result.errors_hash[:email]).to include("must be a valid email")
      end
    end
  end
end
```

### Testing Multi-Step Operations

```ruby
RSpec.describe Orders::ProcessOrderOperation do
  describe ".call" do
    let(:valid_params) do
      {
        user_id: 123,
        items: [{ product_id: 1, quantity: 2, price: 29.99 }],
        payment_method: "credit_card"
      }
    end

    it "executes all steps successfully" do
      result = described_class.call(valid_params)

      expect(result).to be_success
      expect(result.value[:id]).to be_present
      expect(result.value[:status]).to eq("confirmed")
    end

    it "stops at first failing step" do
      # Trigger payment failure
      params = valid_params.merge(payment_method: "invalid")

      result = described_class.call(params)

      expect(result).to be_failure
      # Verify later steps weren't executed
    end
  end
end
```

### Mocking Service Calls

```ruby
RSpec.describe Orders::ProcessOrderOperation do
  describe ".call" do
    let(:payment_service) { instance_double(PaymentService) }

    before do
      allow(PaymentService).to receive(:call).and_return(
        double(success?: true, value: { transaction_id: "txn_123" })
      )
    end

    it "uses PaymentService" do
      result = described_class.call(valid_params)

      expect(PaymentService).to have_received(:call).with(
        method: "credit_card",
        amount: anything
      )
      expect(result).to be_success
    end
  end
end
```

## Best Practices

### 1. Keep Operations Focused

Each operation should handle one business workflow:

```ruby
# Good - focused on one workflow
class Users::RegisterOperation < BaseOperation
  # Handles user registration flow
end

class Users::UpdateProfileOperation < BaseOperation
  # Handles profile update flow
end

# Bad - too many responsibilities
class Users::ManageOperation < BaseOperation
  # Handles registration, updates, deletion, etc.
end
```

### 2. Use Namespaces

Organize operations by domain:

```ruby
app/operations/
  users/
    register_operation.rb
    update_profile_operation.rb
    deactivate_operation.rb
  orders/
    create_operation.rb
    cancel_operation.rb
    refund_operation.rb
  payments/
    process_operation.rb
    refund_operation.rb
```

### 3. Validate Early

Use contracts to validate parameters before any business logic:

```ruby
# Good
class MyOperation < BaseOperation
  contract do
    params do
      required(:email).filled(:string)
    end
  end

  def call(params)
    # params are already validated
    user = User.create(params)
    Success(user)
  end
end

# Bad
class MyOperation < BaseOperation
  def call(params)
    # Manual validation mixed with business logic
    return Failure("Email required") if params[:email].blank?
    user = User.create(params)
    Success(user)
  end
end
```

### 4. Return Quickly

Use early returns for failure cases:

```ruby
def call(params)
  return Failure("Not authorized") unless authorized?
  return Failure("Invalid data") unless valid_data?

  # Happy path
  result = perform_operation
  Success(result)
end
```

### 5. Delegate to Services

Extract reusable logic into services:

```ruby
# Good - operation orchestrates, service provides reusable logic
class ProcessOrderOperation < BaseOperation
  def call(params)
    payment_result = yield PaymentService.call(params)
    inventory_result = yield InventoryService.call(params)
    Success(create_order(payment_result, inventory_result))
  end
end

# Bad - operation contains reusable payment logic
class ProcessOrderOperation < BaseOperation
  def call(params)
    # Complex payment logic that could be reused elsewhere
    payment = process_credit_card(params[:card])
    # ...
  end
end
```

### 6. Handle Non-Critical Failures

Some steps failing shouldn't fail the entire operation:

```ruby
def call(params)
  order = yield create_order(params)
  yield process_payment(order)

  # Notification failure shouldn't fail the operation
  send_notification(order)
  # or
  yield send_notification(order)
rescue StandardError => e
  Rails.logger.warn("Notification failed: #{e.message}")
  # Continue anyway
end

Success(order)
```

### 7. Use External Contracts for Complex Validation

Keep large validation schemas in separate files:

```ruby
# app/operations/contracts/orders/process_order_contract.rb
class ProcessOrderContract < Dry::Validation::Contract
  # Complex validation rules
end

# app/operations/orders/process_order_operation.rb
class ProcessOrderOperation < BaseOperation
  contract_class ProcessOrderContract
  # Clean operation file
end
```

### 8. Document Step Dependencies

Make step dependencies clear:

```ruby
def call(params)
  # Step 1: Validate user exists
  user = yield find_user(params[:user_id])

  # Step 2: Check inventory (needs user for location)
  inventory = yield check_inventory(params[:items], user.location)

  # Step 3: Process payment (needs inventory confirmation)
  payment = yield process_payment(params[:payment], inventory.total)

  # Step 4: Create order (needs all previous results)
  order = yield create_order(user, inventory, payment)

  Success(order)
end
```

## Common Patterns

### Pattern: Transaction Wrapper

```ruby
class CreateOrderOperation < BaseOperation
  def call(params)
    ActiveRecord::Base.transaction do
      order = yield create_order(params)
      order_items = yield create_order_items(order, params[:items])
      payment = yield process_payment(order)

      Success(order)
    end
  rescue StandardError => e
    Failure("Transaction failed: #{e.message}")
  end
end
```

### Pattern: Conditional Steps

```ruby
def call(params)
  user = yield create_user(params)

  # Only send welcome email for new users
  yield send_welcome_email(user) if user.created_at > 1.minute.ago

  # Only apply referral bonus if referral code provided
  if params[:referral_code].present?
    yield apply_referral_bonus(user, params[:referral_code])
  end

  Success(user)
end
```

### Pattern: Parallel Steps (Non-Dependent)

```ruby
def call(params)
  order = yield create_order(params)

  # These can happen in parallel (conceptually)
  # In practice, they run sequentially but are independent
  notification_result = send_notification(order)
  analytics_result = track_analytics(order)
  cache_result = update_cache(order)

  # Even if side effects fail, return success
  Success(order)
end
```

### Pattern: Retry Logic

```ruby
def call(params)
  order = yield create_order(params)
  payment = yield process_payment_with_retry(order)
  Success(order)
end

private

def process_payment_with_retry(order, attempts = 3)
  result = PaymentService.call(order: order)
  return Success(result.value) if result.success?

  if attempts > 1
    sleep(1)
    process_payment_with_retry(order, attempts - 1)
  else
    Failure("Payment failed after #{attempts} attempts")
  end
end
```

## Troubleshooting

### Common Issues

**Issue: "Contract not found"**
```ruby
# Make sure to require the contract if it's external
require_relative "../contracts/orders/process_order_contract"

class ProcessOrderOperation < BaseOperation
  contract_class ProcessOrderContract
end
```

**Issue: "Yield called outside of do notation"**
```ruby
# Include the do notation module
class MyOperation < BaseOperation
  include Dry::Monads[:result, :do]  # Add this!

  def call(params)
    result = yield some_step
  end
end
```

**Issue: "NoMethodError: undefined method `value!' for nil"**
```ruby
# Make sure you're returning Success or Failure from steps
def my_step(params)
  result = some_logic
  Success(result)  # Don't forget to wrap in Success!
end
```

## Conclusion

Operations provide a clean, consistent way to handle business workflows in Rails applications. By combining dry-validation for parameter validation, dry-monads for error handling, and a step-based execution model, they make complex business logic easier to write, test, and maintain.

Remember:
- Use Operations for complex workflows called from controllers
- Use Services for reusable business logic
- Validate parameters early with contracts
- Return Success or Failure from every step
- Test each step and the full workflow
- Keep operations focused on orchestration
