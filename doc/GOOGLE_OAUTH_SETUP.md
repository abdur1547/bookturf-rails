# Google OAuth Setup Guide

## Quick Start

The Google OAuth is already configured in the application, but you need to add your credentials to enable it.

## Step 1: Create Google OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the **Google+ API** or **Google Identity Services**
4. Go to **Credentials** → **Create Credentials** → **OAuth 2.0 Client ID**
5. Choose **Web application**
6. Add authorized redirect URIs:
   - Development: `http://localhost:3000/users/auth/google_oauth2/callback`
   - Production: `https://yourdomain.com/users/auth/google_oauth2/callback`
7. Copy your **Client ID** and **Client Secret**

## Step 2: Add Credentials to Your App

### For Development:

Edit `config/application.yml`:

```yaml
development:
  GOOGLE_CLIENT_ID: "your-client-id.apps.googleusercontent.com"
  GOOGLE_CLIENT_SECRET: "your-client-secret"
```

### For Production:

Either use `config/application.yml`:

```yaml
production:
  GOOGLE_CLIENT_ID: "your-production-client-id.apps.googleusercontent.com"
  GOOGLE_CLIENT_SECRET: "your-production-client-secret"
```

Or set environment variables on your server:
```bash
export GOOGLE_CLIENT_ID="your-client-id"
export GOOGLE_CLIENT_SECRET="your-client-secret"
```

## Step 3: Restart Your Server

After adding credentials, restart your Rails server:

```bash
# Stop the server (Ctrl+C)
# Start it again
rails server
```

## Step 4: Test Google Sign-In

1. Visit `http://localhost:3000/users/sign_in`
2. Click the **"Sign in with Google"** button
3. You should be redirected to Google's login page
4. After authenticating, you'll be redirected back to your app

## How It Works

### Configuration

The Google OAuth is configured in `config/initializers/devise.rb`:

```ruby
config.omniauth :google_oauth2,
  ENV['GOOGLE_CLIENT_ID'],
  ENV['GOOGLE_CLIENT_SECRET'],
  {
    scope: 'email,profile',
    prompt: 'select_account',
    image_aspect_ratio: 'square',
    image_size: 50,
    skip_jwt: true
  }
```

### Routes

The following routes are available:

- `POST /users/auth/google_oauth2` - Initiates Google OAuth
- `GET/POST /users/auth/google_oauth2/callback` - Handles the callback from Google

### Controller

The callback is handled by `app/controllers/users/omniauth_callbacks_controller.rb`:

```ruby
def google_oauth2
  @user = User.from_omniauth(auth_params)
  
  if @user.persisted?
    sign_in_and_redirect @user, event: :authentication
    set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
  else
    session["devise.google_data"] = auth_params.except(:extra)
    redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
  end
end
```

### User Model

Users are created/found using the `from_omniauth` method in `app/models/user.rb`:

```ruby
def self.from_omniauth(auth)
  where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
    user.email = auth.info.email
    user.name = auth.info.name
    user.avatar_url = auth.info.image
    user.password = Devise.friendly_token[0, 20]
  end
end
```

### Views

Google sign-in buttons are added to:
- `app/views/devise/sessions/new.html.erb` (Sign in page)
- `app/views/devise/registrations/new.html.erb` (Sign up page)

## Troubleshooting

### "Sign in with Google" button not working

1. **Check credentials are set:**
   ```bash
   rails console
   ENV['GOOGLE_CLIENT_ID']  # Should return your client ID
   ENV['GOOGLE_CLIENT_SECRET']  # Should return your client secret
   ```

2. **Verify redirect URI:**
   - Must exactly match what's in Google Console
   - Check for trailing slashes or http vs https

3. **Check Google Console settings:**
   - OAuth consent screen is configured
   - App is not in "Testing" mode (or add test users)
   - Redirect URI is added to authorized list

### "redirect_uri_mismatch" error

This means the callback URL doesn't match what's in Google Console.

**Fix:**
1. Go to Google Console → Credentials
2. Edit your OAuth 2.0 Client ID
3. Add the exact URL: `http://localhost:3000/users/auth/google_oauth2/callback`
4. Save and try again

### User not being created

Check the logs:
```bash
tail -f log/development.log
```

Common issues:
- Email already exists (Google email matches existing user)
- Validation errors on User model
- Missing required fields (name, email)

### Development without Google credentials

If you don't have Google credentials yet, you can still use:
- Email/password sign up: `/users/sign_up`
- Email/password sign in: `/users/sign_in`

The Google button will appear but won't work until credentials are added.

## Security Notes

### Never commit credentials to Git

Your `config/application.yml` is already in `.gitignore`. Never commit it!

### Production Security

For production, consider:
1. Using environment variables instead of `application.yml`
2. Storing secrets in Rails credentials:
   ```bash
   EDITOR="code --wait" rails credentials:edit
   ```
   
   ```yaml
   google:
     client_id: your-client-id
     client_secret: your-client-secret
   ```
   
   Then update `config/initializers/devise.rb`:
   ```ruby
   config.omniauth :google_oauth2,
     Rails.application.credentials.dig(:google, :client_id),
     Rails.application.credentials.dig(:google, :client_secret),
     # ... options
   ```

3. Using a secrets manager (AWS Secrets Manager, HashiCorp Vault, etc.)

## Additional OAuth Providers

To add more providers (Facebook, GitHub, etc.):

1. Add the gem to `Gemfile`:
   ```ruby
   gem 'omniauth-facebook'
   gem 'omniauth-github'
   ```

2. Add configuration to `config/initializers/devise.rb`:
   ```ruby
   config.omniauth :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET']
   config.omniauth :github, ENV['GITHUB_CLIENT_ID'], ENV['GITHUB_CLIENT_SECRET']
   ```

3. Update User model:
   ```ruby
   devise :omniauthable, omniauth_providers: [:google_oauth2, :facebook, :github]
   ```

4. Add methods to omniauth_callbacks_controller.rb:
   ```ruby
   def facebook
     handle_omniauth("Facebook")
   end
   
   def github
     handle_omniauth("GitHub")
   end
   
   private
   
   def handle_omniauth(kind)
     @user = User.from_omniauth(auth_params)
     if @user.persisted?
       sign_in_and_redirect @user, event: :authentication
       set_flash_message(:notice, :success, kind: kind) if is_navigational_format?
     else
       session["devise.#{kind.downcase}_data"] = auth_params.except(:extra)
       redirect_to new_user_registration_url
     end
   end
   ```

## Resources

- [Devise Documentation](https://github.com/heartcombo/devise)
- [OmniAuth Google OAuth2](https://github.com/zquestz/omniauth-google-oauth2)
- [Google Identity Platform](https://developers.google.com/identity)
- [Google Cloud Console](https://console.cloud.google.com/)
