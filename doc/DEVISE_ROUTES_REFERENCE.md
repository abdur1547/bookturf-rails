# Devise Routes Reference

## Overview
This document provides a quick reference for all Devise authentication routes configured in the application.

## Configured Controllers
All Devise controllers are customizable and located in `app/controllers/users/`:
- `sessions_controller.rb` - Sign in/out
- `registrations_controller.rb` - Sign up and account management
- `passwords_controller.rb` - Password reset
- `confirmations_controller.rb` - Email confirmation
- `unlocks_controller.rb` - Account unlock
- `omniauth_callbacks_controller.rb` - Google OAuth and other providers

## Available Routes

### Sessions (Sign In/Out)
```
GET    /users/sign_in   → users/sessions#new        (Login page)
POST   /users/sign_in   → users/sessions#create     (Submit login)
DELETE /users/sign_out  → users/sessions#destroy    (Logout)
```

**Helper methods:**
- `new_user_session_path` - Login page
- `user_session_path` - Login form submission
- `destroy_user_session_path` - Logout

### Registrations (Sign Up)
```
GET    /users/sign_up   → users/registrations#new       (Sign up page)
POST   /users           → users/registrations#create    (Submit sign up)
GET    /users/edit      → users/registrations#edit      (Edit account)
PATCH  /users           → users/registrations#update    (Update account)
DELETE /users           → users/registrations#destroy   (Delete account)
GET    /users/cancel    → users/registrations#cancel    (Cancel registration)
```

**Helper methods:**
- `new_user_registration_path` - Sign up page
- `user_registration_path` - Form submission
- `edit_user_registration_path` - Edit account page

### Passwords (Reset Password)
```
GET    /users/password/new   → users/passwords#new      (Request reset)
POST   /users/password       → users/passwords#create   (Send reset email)
GET    /users/password/edit  → users/passwords#edit     (Reset form)
PATCH  /users/password       → users/passwords#update   (Update password)
```

**Helper methods:**
- `new_user_password_path` - Request password reset
- `edit_user_password_path` - Reset password form
- `user_password_path` - Form submission

### OmniAuth (Google OAuth2)
```
POST   /users/auth/google_oauth2           → users/omniauth_callbacks#passthru
GET    /users/auth/google_oauth2/callback  → users/omniauth_callbacks#google_oauth2
POST   /users/auth/google_oauth2/callback  → users/omniauth_callbacks#google_oauth2
```

**Helper methods:**
- `user_google_oauth2_omniauth_authorize_path` - Initiate Google OAuth

### Confirmations (Email Confirmation)
```
GET    /users/confirmation/new  → users/confirmations#new      (Request confirmation)
POST   /users/confirmation      → users/confirmations#create   (Resend confirmation)
GET    /users/confirmation      → users/confirmations#show     (Confirm email)
```

**Helper methods:**
- `new_user_confirmation_path` - Request confirmation email
- `user_confirmation_path` - Confirmation token link

### Unlocks (Account Unlock)
```
GET    /users/unlock/new  → users/unlocks#new      (Request unlock)
POST   /users/unlock      → users/unlocks#create   (Send unlock email)
GET    /users/unlock      → users/unlocks#show     (Unlock account)
```

**Helper methods:**
- `new_user_unlock_path` - Request unlock instructions
- `user_unlock_path` - Unlock token link

## Customizable Views

All views are located in `app/views/devise/` and can be customized:

### Session Views
- `sessions/new.html.erb` - Login form

### Registration Views
- `registrations/new.html.erb` - Sign up form
- `registrations/edit.html.erb` - Edit account form

### Password Views
- `passwords/new.html.erb` - Request password reset
- `passwords/edit.html.erb` - Reset password form

### Mailer Views
- `mailer/confirmation_instructions.html.erb`
- `mailer/email_changed.html.erb`
- `mailer/password_change.html.erb`
- `mailer/reset_password_instructions.html.erb`
- `mailer/unlock_instructions.html.erb`

### Shared Views
- `shared/_error_messages.html.erb` - Form error messages
- `shared/_links.html.erb` - Navigation links (forgot password, sign up, etc.)

## Protecting Routes

To require authentication for a controller action:

```ruby
class MyController < ApplicationController
  before_action :authenticate_user!
  
  def index
    # Only accessible to signed-in users
  end
end
```

To require authentication for specific actions:

```ruby
class MyController < ApplicationController
  before_action :authenticate_user!, only: [:edit, :update, :destroy]
  
  def show
    # Accessible to everyone
  end
  
  def edit
    # Only accessible to signed-in users
  end
end
```

## Current User

Access the currently signed-in user in controllers and views:

```ruby
current_user          # Returns the current user or nil
user_signed_in?       # Returns true if user is signed in
current_user.email    # Access user attributes
```

## Redirects After Sign In/Out

Customize redirect paths by overriding these methods in your controllers:

```ruby
# In app/controllers/application_controller.rb
def after_sign_in_path_for(resource)
  dashboard_path  # Redirect to dashboard after sign in
end

def after_sign_out_path_for(resource_or_scope)
  root_path  # Redirect to home after sign out
end
```

## Google OAuth Configuration

To enable Google OAuth in production, you need to:

1. Set up credentials at https://console.cloud.google.com/
2. Add credentials to Rails credentials:

```bash
EDITOR="code --wait" rails credentials:edit
```

```yaml
google:
  client_id: YOUR_CLIENT_ID
  client_secret: YOUR_CLIENT_SECRET
```

3. Configure OmniAuth in `config/initializers/devise.rb`:

```ruby
config.omniauth :google_oauth2,
  Rails.application.credentials.dig(:google, :client_id),
  Rails.application.credentials.dig(:google, :client_secret),
  {
    scope: 'email,profile',
    prompt: 'select_account',
    image_aspect_ratio: 'square',
    image_size: 50
  }
```

4. Add authorized redirect URIs in Google Console:
   - Development: `http://localhost:3000/users/auth/google_oauth2/callback`
   - Production: `https://yourdomain.com/users/auth/google_oauth2/callback`

## Testing Routes

View all available routes:

```bash
rails routes | grep user
```

Test authentication in Rails console:

```bash
rails console
```

```ruby
# Create a user
user = User.create!(
  email: 'test@example.com',
  name: 'Test User',
  password: 'password123',
  password_confirmation: 'password123'
)

# Sign in a user in tests
sign_in user
```

## Common Issues

### Turbo and Devise
If you experience issues with Devise and Turbo, add `data: { turbo: false }` to forms:

```erb
<%= button_to "Sign in with Google", 
    user_google_oauth2_omniauth_authorize_path, 
    method: :post, 
    data: { turbo: false } %>
```

### CSRF Protection
For API requests, you may need to skip CSRF protection:

```ruby
class Api::V1::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token
end
```

### Session Store
Ensure you have a proper session store configured for production in `config/initializers/session_store.rb`.

## Additional Resources

- [Devise Documentation](https://github.com/heartcombo/devise)
- [Devise Wiki](https://github.com/heartcombo/devise/wiki)
- [OmniAuth Documentation](https://github.com/omniauth/omniauth)
- [Google OAuth2 Setup](https://github.com/zquestz/omniauth-google-oauth2)
