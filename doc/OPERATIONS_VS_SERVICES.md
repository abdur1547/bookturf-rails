# Operations vs Services - Quick Reference

## Overview

This Rails application uses two complementary patterns for business logic:

| Pattern | Purpose | Called From | Returns |
|---------|---------|-------------|---------|
| **Operations** | Orchestrate complex workflows | Controllers | BaseOperation::Result |
| **Services** | Reusable business logic | Operations, other Services | ServiceResult |

## When to Use What

### Use Operations When:
- ✅ Called directly from controllers
- ✅ Complex workflows with multiple steps
- ✅ Need parameter validation before execution
- ✅ Logic can fail at multiple points
- ✅ Need to coordinate multiple services

### Use Services When:
- ✅ Reusable business logic across operations
- ✅ Simple, focused functionality
- ✅ Don't need complex parameter validation
- ✅ Called from operations or other services

## Architecture Flow

```
Controller
    ↓
Operation (validates params, orchestrates workflow)
    ↓
Services (reusable business logic)
    ↓
Models
```

## Example Comparison

### Operation Example: User Registration

```ruby
# app/operations/users/register_operation.rb
module Users
  class RegisterOperation < BaseOperation
    # 1. Validates parameters using dry-validation
    contract do
      params do
        required(:email).filled(:string)
        required(:password).filled(:string, min_size?: 8)
        required(:first_name).filled(:string)
        required(:last_name).filled(:string)
      end
    end

    # 2. Orchestrates multiple steps
    def call(params)
      # Can use services for reusable logic
      user = yield create_user(params)
      yield send_welcome_email(user)
      yield setup_trial_subscription(user)
      
      Success(user)
    end

    private

    def create_user(params)
      user = User.create(params)
      user.persisted? ? Success(user) : Failure(user.errors)
    end

    def send_welcome_email(user)
      # Delegate to service
      result = EmailService.call(to: user.email, template: :welcome)
      result.success? ? Success(true) : Failure(result.errors)
    end
  end
end

# Controller
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

### Service Example: Email Sending

```ruby
# app/services/email_service.rb
class EmailService < BaseService
  def call(to:, template:, **options)
    mailer = UserMailer.send(template, to, options)
    mailer.deliver_now
    
    success(sent: true, to: to)
  rescue StandardError => e
    failure("Failed to send email: #{e.message}")
  end
end

# Used by operations
result = EmailService.call(to: "user@example.com", template: :welcome)
```

## Key Differences

### Parameter Validation

**Operations:**
```ruby
# Built-in validation with dry-validation
contract do
  params do
    required(:email).filled(:string)
    required(:age).filled(:integer, gt?: 18)
  end
end
# Invalid params are rejected before call() runs
```

**Services:**
```ruby
# Manual validation in call method
def call(email:, age:)
  return failure("Email required") if email.blank?
  return failure("Must be adult") if age < 18
  # ... business logic
end
```

### Error Handling

**Operations:**
```ruby
# Railway-oriented programming with do notation
def call(params)
  user = yield create_user(params)      # Stops here if fails
  profile = yield create_profile(user)  # Skipped if previous failed
  Success(user)
end
```

**Services:**
```ruby
# Explicit success/failure returns
def call(params)
  user = create_user(params)
  return failure("User creation failed") unless user.persisted?
  
  success(user)
end
```

### Return Values

**Operations:**
```ruby
result = MyOperation.call(params)

result.success?        # Boolean
result.failure?        # Boolean
result.value          # Success data
result.errors         # Error data (string, hash, or validation result)
result.errors_hash    # Normalized error hash
```

**Services:**
```ruby
result = MyService.call(params)

result.success?        # Boolean
result.failure?        # Boolean
result.value          # Success data
result.errors         # Error message (string)
```

## Real-World Example

### Order Processing Operation

```ruby
# app/operations/orders/process_order_operation.rb
module Orders
  class ProcessOrderOperation < BaseOperation
    include Dry::Monads[:result, :do]

    # Validate complex order structure
    contract_class ProcessOrderContract

    def call(params)
      # Step 1: Calculate totals
      subtotal = yield calculate_subtotal(params[:items])
      
      # Step 2: Apply coupon (uses CouponService)
      discount = yield apply_coupon(params[:coupon_code], subtotal)
      total = subtotal - discount
      
      # Step 3: Process payment (uses PaymentService)
      payment = yield process_payment(params[:payment_method], total)
      
      # Step 4: Update inventory (uses InventoryService)
      yield update_inventory(params[:items])
      
      # Step 5: Create order record
      order = yield create_order(params, total, payment)
      
      # Step 6: Send confirmation (uses NotificationService)
      yield send_confirmation(params[:user_id], order)
      
      Success(order)
    end

    private

    def apply_coupon(code, amount)
      # Delegate to reusable service
      result = CouponService.call(code: code, amount: amount)
      result.success? ? Success(result.value) : Failure(result.errors)
    end

    def process_payment(method, amount)
      # Delegate to reusable service
      result = PaymentService.call(method: method, amount: amount)
      result.success? ? Success(result.value) : Failure(result.errors)
    end

    def update_inventory(items)
      # Delegate to reusable service
      result = InventoryService.call(items: items)
      result.success? ? Success(result.value) : Failure(result.errors)
    end

    def send_confirmation(user_id, order)
      # Delegate to reusable service
      result = NotificationService.call(user_id: user_id, order: order)
      # Non-critical - log but don't fail
      Success(true)
    rescue StandardError => e
      Rails.logger.warn("Confirmation failed: #{e.message}")
      Success(false)
    end
  end
end
```

### Payment Service (Reusable)

```ruby
# app/services/payment_service.rb
class PaymentService < BaseService
  def call(method:, amount:)
    case method
    when "credit_card"
      process_credit_card(amount)
    when "paypal"
      process_paypal(amount)
    when "stripe"
      process_stripe(amount)
    else
      failure("Invalid payment method")
    end
  end

  private

  def process_credit_card(amount)
    # Payment processing logic
    transaction = CreditCardGateway.charge(amount)
    
    if transaction.success?
      success(
        transaction_id: transaction.id,
        amount: amount,
        status: "completed"
      )
    else
      failure("Payment declined")
    end
  rescue StandardError => e
    failure("Payment error: #{e.message}")
  end

  # ... other payment methods
end
```

## Testing Comparison

### Testing Operations

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

    it "processes order successfully" do
      result = described_class.call(valid_params)

      expect(result).to be_success
      expect(result.value[:status]).to eq("confirmed")
    end

    it "fails when payment is declined" do
      allow(PaymentService).to receive(:call).and_return(
        double(success?: false, errors: "Payment declined")
      )

      result = described_class.call(valid_params)

      expect(result).to be_failure
    end

    it "validates parameters" do
      result = described_class.call(user_id: 123)  # missing items

      expect(result).to be_failure
      expect(result.errors_hash).to have_key(:items)
    end
  end
end
```

### Testing Services

```ruby
RSpec.describe PaymentService do
  describe ".call" do
    it "processes credit card payment" do
      result = described_class.call(method: "credit_card", amount: 100.0)

      expect(result).to be_success
      expect(result.value[:transaction_id]).to be_present
    end

    it "fails for invalid payment method" do
      result = described_class.call(method: "bitcoin", amount: 100.0)

      expect(result).to be_failure
      expect(result.errors).to include("Invalid payment method")
    end
  end
end
```

## Summary

| Aspect | Operations | Services |
|--------|-----------|----------|
| **Primary Use** | Workflow orchestration | Reusable logic |
| **Called From** | Controllers | Operations, Services |
| **Validation** | dry-validation contracts | Manual validation |
| **Complexity** | Multi-step workflows | Focused functionality |
| **Error Handling** | Railway-oriented (do notation) | Explicit returns |
| **Return Type** | BaseOperation::Result | ServiceResult |
| **Dependencies** | dry-validation, dry-monads | None (built-in) |

## Best Practice

1. **Controller** calls **Operation**
2. **Operation** orchestrates workflow and validates params
3. **Operation** delegates to **Services** for reusable logic
4. **Services** contain focused business logic
5. Both return consistent Result objects

This separation keeps code organized, testable, and maintainable!
