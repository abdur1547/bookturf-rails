# Service Objects Pattern

## Overview

This Rails application uses the **Service Object** pattern to encapsulate business logic. All services inherit from `BaseService`, which provides a consistent interface and error handling.

## Why Service Objects?

- ✅ **Single Responsibility**: Each service has one clear purpose
- ✅ **Testability**: Easy to test in isolation
- ✅ **Reusability**: Can be called from controllers, jobs, or other services
- ✅ **Maintainability**: Business logic is organized and easy to find
- ✅ **Consistent Error Handling**: Standardized success/failure responses

## BaseService

The `BaseService` class provides:
- Class method `.call(*args, **kwargs)` - instantiates and executes the service
- Instance method `#call` - must be implemented by subclasses
- Helper methods `success(data)` and `failure(error)` - return `ServiceResult` objects

## ServiceResult

The `ServiceResult` class (separate from BaseService) provides:
- `#success?` - returns true if operation succeeded
- `#failure?` - returns true if operation failed
- `#data` - access returned data (on success)
- `#error` - access error message/object (on failure)
- Can be used independently outside of services

## Creating Your Own Service

```ruby
# 1. Create service file: app/services/my_service.rb
class MyService < BaseService
  # No initialize needed - params go directly in call
  def call(param1, param2:)
    @param1 = param1
    @param2 = param2
    
    return failure('Validation error') unless valid?
    
    result = do_work
    success(result)
  rescue StandardError => e
    failure(e.message)
  end

  private

  def valid?
    @param1.present? && @param2.present?
  end

  def do_work
    # Your business logic
  end
end

**Benefits of this approach:**
- ✅ No need to define `initialize` method
- ✅ Parameters passed directly to `call`
- ✅ Cleaner, more concise services
- ✅ Less boilerplate code

### 2. Calling a Service

```ruby
# In a controller
def create
  result = CreateUserService.call(email: params[:email], password: params[:password])
  
  if result.success?
    @user = result.data
    redirect_to @user, notice: 'User created successfully'
  else
    flash.now[:alert] = result.error
    render :new
  end
end

# In a job
def perform(user_id)
  result = SendWelcomeEmailService.call(user_id: user_id)
  raise result.error if result.failure?
end

# In another service
def call
  user_result = CreateUserService.call(email: @email)
  return failure(user_result.error) if user_result.failure?
  
  user = user_result.data
  # Continue with user...
end
```

## Best Practices

### ✅ DO

1. **Name services descriptively with verbs**
   - `CreateUserService`
   - `SendEmailNotificationService`
   - `CalculateTotalPriceService`
   - `ProcessPaymentService`

2. **Keep services focused on one responsibility**
   ```ruby
   # Good - single responsibility
   class CreateUserService < BaseService
     # Only handles user creation
   end
   
   # Bad - multiple responsibilities
   class UserService < BaseService
     # Creates, updates, deletes users
   end
   ```

3. **Validate inputs early**
   ```ruby
   def call
     return failure('Email required') if @email.blank?
     return failure('Invalid email format') unless valid_email?
     
     # Continue with logic...
   end
   ```

4. **Return meaningful data in success**
   ```ruby
   success(
     user: user,
     token: authentication_token,
     expires_at: 24.hours.from_now
   )
   ```

5. **Provide clear error messages**
   ```ruby
   failure('Payment failed: Insufficient funds')
   failure('User not found with ID: #{user_id}')
   failure(errors: user.errors.full_messages)
   ```

6. **Handle exceptions gracefully**
   ```ruby
   def call
     # Logic here
   rescue ActiveRecord::RecordNotFound => e
     failure("Record not found: #{e.message}")
   rescue StandardError => e
     Rails.logger.error("#{self.class.name} failed: #{e.message}")
     failure('An unexpected error occurred')
   end
   ```

7. **Use private methods for clarity**
   ```ruby
   def call
     return failure(validation_errors) unless valid?
     
     user = create_user
     send_welcome_email(user)
     
     success(user)
   end
   
   private
   
   def valid?
     # Validation logic
   end
   
   def validation_errors
     # Return error messages
   end
   
   def create_user
     # User creation logic
   end
   
   def send_welcome_email(user)
     # Email sending logic
   end
   ```

### ❌ DON'T

1. **Don't put controller logic in services**
   ```ruby
   # Bad - controller concerns
   def call
     render json: { user: @user }, status: :created
   end
   
   # Good - return data, let controller handle rendering
   def call
     success(@user)
   end
   ```

2. **Don't access params or request directly**
   ```ruby
   # Bad
   def call
     @email = params[:email]
   end
   
   # Good - pass needed data explicitly
   def initialize(email:)
     @email = email
   end
   ```

3. **Don't return inconsistent result types**
   ```ruby
   # Bad - mixing return types
   def call
     return nil if error
     return true if success
     { user: user }
   end
   
   # Good - always return Result object
   def call
     return failure('Error') if error
     success(user: user)
   end
   ```

4. **Don't make services too complex**
   ```ruby
   # Bad - too many responsibilities
   class CreateUserAndSetupAccountAndSendEmailsService
     # 200 lines of code...
   end
   
   # Good - break into smaller services
   class CreateUserService
     def call
       # Create user
       user_result = User.create(@attributes)
       return failure(user_result.errors) unless user_result.persisted?
       
       # Call other services
       SetupAccountService.call(user: user_result)
       SendWelcomeEmailService.call(user: user_result)
       
       success(user_result)
     end
   end
   ```

## Testing Services

### RSpec Example

```ruby
require 'rails_helper'

RSpec.describe CreateUserService, type: :service do
  describe '.call' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          email: 'test@example.com',
          password: 'password123',
          first_name: 'John'
        }
      end

      it 'creates a user' do
        expect {
          described_class.call(**valid_params)
        }.to change(User, :count).by(1)
      end

      it 'returns success result' do
        result = described_class.call(**valid_params)

        expect(result).to be_success
        expect(result.data).to be_a(User)
        expect(result.data.email).to eq('test@example.com')
      end
    end

    context 'with invalid parameters' do
      it 'returns failure for blank email' do
        result = described_class.call(email: '', password: 'password123')

        expect(result).to be_failure
        expect(result.error).to include('Email')
      end

      it 'does not create user' do
        expect {
          described_class.call(email: '', password: 'password123')
        }.not_to change(User, :count)
      end
    end

    context 'when exception occurs' do
      before do
        allow(User).to receive(:create!).and_raise(StandardError, 'Database error')
      end

      it 'returns failure with error message' do
        result = described_class.call(email: 'test@example.com', password: 'pass')

        expect(result).to be_failure
        expect(result.error).to include('Database error')
      end
    end
  end
end
```

## Common Patterns

### 1. Composition - Calling Other Services

```ruby
class RegisterUserService < BaseService
  def call
    # Create user
    user_result = CreateUserService.call(email: @email, password: @password)
    return user_result if user_result.failure?
    
    user = user_result.data
    
    # Setup account
    account_result = SetupAccountService.call(user: user)
    return account_result if account_result.failure?
    
    # Send welcome email
    SendWelcomeEmailService.call(user: user)
    
    success(user: user, account: account_result.data)
  end
end
```

### 2. Transaction Handling

```ruby
class ProcessOrderService < BaseService
  def call
    ActiveRecord::Base.transaction do
      order = create_order
      process_payment
      update_inventory
      send_confirmation_email
      
      success(order)
    end
  rescue StandardError => e
    failure("Order processing failed: #{e.message}")
  end
end
```

### 3. Conditional Logic

```ruby
class NotifyUserService < BaseService
  def call
    result = if @user.prefers_email?
               send_email
             elsif @user.prefers_sms?
               send_sms
             else
               send_push_notification
             end
    
    return failure(result.error) if result.failure?
    success(notification_sent: true, method: result.data[:method])
  end
end
```

### 4. Background Processing

```ruby
# Service
class GenerateReportService < BaseService
  def call
    report = build_report
    file_path = save_report(report)
    
    success(file_path: file_path, generated_at: Time.current)
  end
end

# Job
class GenerateReportJob < ApplicationJob
  def perform(user_id)
    result = GenerateReportService.call(user_id: user_id)
    
    if result.success?
      # Notify user
      UserMailer.report_ready(user_id, result.data[:file_path]).deliver_later
    else
      # Log error
      Rails.logger.error("Report generation failed: #{result.error}")
    end
  end
end
```

## File Organization

```
app/
  services/
    base_service.rb                     # Base class
    service_result.rb                   # Result object (reusable)
    
    # User-related services
    users/
      create_user_service.rb
      update_user_service.rb
      delete_user_service.rb
    
    # Payment-related services
    payments/
      process_payment_service.rb
      refund_payment_service.rb
    
    # Notification services
    notifications/
      send_email_service.rb
      send_sms_service.rb
    
    # Other services
    calculate_total_price_service.rb
    generate_report_service.rb

spec/
  services/
    base_service_spec.rb
    service_result_spec.rb
    users/
      create_user_service_spec.rb
    # ... matching structure
```

## Using ServiceResult Independently

`ServiceResult` is a standalone class that can be used outside of services:

```ruby
# In a controller action
def create
  if params[:email].blank?
    result = ServiceResult.failure('Email is required')
  else
    result = ServiceResult.success(user: @user)
  end
  
  if result.success?
    redirect_to result.data[:user]
  else
    flash[:error] = result.error
    render :new
  end
end

# In a job
def perform(data)
  result = process_data(data)
  
  if result.failure?
    retry_job(wait: 5.minutes)
  end
end

# In a custom command/query object
class UserQuery
  def self.find_active
    users = User.where(active: true)
    
    if users.any?
      ServiceResult.success(users)
    else
      ServiceResult.failure('No active users found')
    end
  end
end
```

## Handling Multiple Errors

```ruby
def call
  errors = []
  errors << 'Email is required' if @email.blank?
  errors << 'Password is too short' if @password.length < 8
  
  return failure(errors) if errors.any?
  
  # Continue...
end

# Access errors
result = MyService.call(params)
if result.failure?
  # result.error is an array of error messages
  result.error.each { |err| puts err }
end
```

## Resources

- [BaseService Implementation](../app/services/base_service.rb)
- [BaseService Specs](../spec/services/base_service_spec.rb)
- [Example: CalculateTotalPriceService](../app/services/calculate_total_price_service.rb)

## Questions?

This pattern keeps your Rails app organized, testable, and maintainable. Start with simple services and evolve as needed!
