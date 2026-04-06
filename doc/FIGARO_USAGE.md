# Figaro Environment Variable Management

## Overview

Figaro is installed for managing environment variables in this Rails application. It uses a simple YAML file (`config/application.yml`) that is **not committed to git**, making it easy to manage different configurations per environment.

## Quick Start

### 1. Set Up Your Environment Variables

Copy the example file and add your actual values:

```bash
cp config/application.yml.example config/application.yml
```

Then edit `config/application.yml` with your actual credentials.

### 2. Access Variables in Your Code

```ruby
# Anywhere in your Rails app
ENV['GOOGLE_CLIENT_ID']
ENV['JWT_SECRET_KEY']
ENV['STRIPE_API_KEY']
```

### 3. Environment-Specific Variables

```yaml
# config/application.yml

# Available in all environments
SHARED_KEY: "value"

development:
  API_HOST: "http://localhost:3000"

test:
  API_HOST: "http://localhost:3000"

production:
  API_HOST: "https://api.yourdomain.com"
```

## Common Commands

### Generate a Secret Key (for JWT, etc.)

```bash
bundle exec rake secret
```

Copy the output to your `application.yml` for `JWT_SECRET_KEY`.

### Deploy to Heroku

```bash
# Set all production variables on Heroku
bundle exec figaro heroku:set -e production

# Or set specific environment
bundle exec figaro heroku:set -e staging
```

### Check Current Environment Variables

```bash
# In Rails console
rails console
> ENV['GOOGLE_CLIENT_ID']
> Figaro.env.google_client_id  # Alternative syntax
```

## File Structure

```
config/
├── application.yml          # Your actual config (NOT in git)
└── application.yml.example  # Template (committed to git)
```

## Usage Examples

### In Controllers

```ruby
class ApplicationController < ActionController::Base
  def frontend_url
    "#{ENV['APP_PROTOCOL']}://#{ENV['APP_HOST']}"
  end
end
```

### In Initializers

```ruby
# config/initializers/stripe.rb
Stripe.api_key = ENV['STRIPE_API_KEY']
```

### In Devise Configuration

```ruby
# config/initializers/devise.rb
config.omniauth :google_oauth2, 
  ENV['GOOGLE_CLIENT_ID'], 
  ENV['GOOGLE_CLIENT_SECRET'],
  {
    scope: 'email,profile',
    prompt: 'select_account',
    image_aspect_ratio: 'square',
    image_size: 50
  }
```

### In Action Mailer

```ruby
# config/environments/production.rb
config.action_mailer.smtp_settings = {
  address:              ENV['SMTP_ADDRESS'],
  port:                 ENV['SMTP_PORT'],
  domain:               ENV['SMTP_DOMAIN'],
  user_name:            ENV['SMTP_USERNAME'],
  password:             ENV['SMTP_PASSWORD'],
  authentication:       'plain',
  enable_starttls_auto: true
}
```

## Required Variables for Authentication

When implementing authentication, you'll need:

```yaml
# config/application.yml

# JWT Authentication
JWT_SECRET_KEY: "generate-with-rake-secret"
JWT_EXPIRATION_HOURS: "24"

# Google OAuth
GOOGLE_CLIENT_ID: "your-client-id.apps.googleusercontent.com"
GOOGLE_CLIENT_SECRET: "your-client-secret"

development:
  GOOGLE_OAUTH_REDIRECT_URI: "http://localhost:3000/users/auth/google_oauth2/callback"

production:
  GOOGLE_OAUTH_REDIRECT_URI: "https://yourdomain.com/users/auth/google_oauth2/callback"
```

## Best Practices

### ✅ Do's

- **DO** keep `application.yml` out of git (already in .gitignore)
- **DO** commit `application.yml.example` with dummy values
- **DO** document all required variables in the example file
- **DO** use different credentials for each environment
- **DO** rotate secrets regularly
- **DO** use strong, randomly generated secrets

### ❌ Don'ts

- **DON'T** commit real credentials to git
- **DON'T** share your `application.yml` file
- **DON'T** use production credentials in development
- **DON'T** hardcode sensitive values in your code
- **DON'T** use simple/guessable secrets

## Security Notes

### Generate Strong Secrets

```bash
# For JWT_SECRET_KEY (at least 32 characters)
bundle exec rake secret

# For other secrets (OpenSSL)
openssl rand -hex 32

# For passwords (random string)
ruby -rsecurerandom -e 'puts SecureRandom.alphanumeric(32)'
```

### Required Minimum Security

```yaml
# Minimum 32 characters for JWT
JWT_SECRET_KEY: "abc123"  # ❌ TOO SHORT!
JWT_SECRET_KEY: "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6"  # ✅ Good

# Use environment-specific secrets
development:
  JWT_SECRET_KEY: "dev-secret-not-for-production"
  
production:
  JWT_SECRET_KEY: "production-secret-minimum-32-chars-long"  # ✅ Different!
```

## Troubleshooting

### Variables Not Loading

1. **Restart your Rails server** after changing `application.yml`
2. Check file is at `config/application.yml` (not `.example`)
3. Verify YAML syntax is correct (use a YAML validator)
4. Check for typos in variable names

### Missing Variables

```ruby
# In your code, add fallbacks for development
api_key = ENV.fetch('API_KEY', 'default-value-for-dev')

# Or raise an error if required
api_key = ENV.fetch('API_KEY') # Raises if missing
```

### Testing with Different Values

```ruby
# In RSpec tests
RSpec.describe 'Something' do
  around do |example|
    ClimateControl.modify(API_KEY: 'test-key') do
      example.run
    end
  end
end

# Or use the database_cleaner pattern
before do
  allow(ENV).to receive(:[]).with('API_KEY').and_return('test-key')
end
```

## Environment Variables Checklist

Before deploying to production, ensure you have:

- [ ] `JWT_SECRET_KEY` - At least 32 characters, randomly generated
- [ ] `GOOGLE_CLIENT_ID` - From Google Cloud Console
- [ ] `GOOGLE_CLIENT_SECRET` - From Google Cloud Console
- [ ] `DATABASE_URL` - PostgreSQL connection string (if applicable)
- [ ] `REDIS_URL` - Redis connection string (if using)
- [ ] `SMTP_*` variables - For sending emails
- [ ] All production URLs use HTTPS
- [ ] All secrets are different from development

## Getting OAuth Credentials

### Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable "Google+ API"
4. Go to "Credentials" → "Create Credentials" → "OAuth 2.0 Client ID"
5. Add authorized redirect URIs:
   - Development: `http://localhost:3000/users/auth/google_oauth2/callback`
   - Production: `https://yourdomain.com/users/auth/google_oauth2/callback`
6. Copy Client ID and Client Secret to `application.yml`

## Additional Resources

- [Figaro GitHub](https://github.com/laserlemon/figaro)
- [Rails Credentials Alternative](https://guides.rubyonrails.org/security.html#custom-credentials)
- [Heroku Config Vars](https://devcenter.heroku.com/articles/config-vars)

## Summary

Figaro makes ENV management simple:

1. ✅ All secrets in one file: `config/application.yml`
2. ✅ Environment-specific values supported
3. ✅ Never committed to git
4. ✅ Easy deployment to Heroku
5. ✅ Simple Ruby/YAML syntax

Just remember: **Never commit `config/application.yml` to git!**
