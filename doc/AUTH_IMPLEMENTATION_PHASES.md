# Authentication Implementation TODO

## Phase 1: Setup & Dependencies ⏱️ ~30 mins

- [ ] 1.1: Add gems to Gemfile
  ```ruby
  # Authentication
  gem 'devise', '~> 4.9'
  gem 'devise-jwt', '~> 0.11'
  gem 'omniauth-google-oauth2', '~> 1.1'
  gem 'omniauth-rails_csrf_protection'
  gem 'rack-cors'
  
  # Optional but recommended
  gem 'jsonapi-serializer'
  ```

- [ ] 1.2: Run `bundle install`

- [ ] 1.3: Install Devise
  ```bash
  rails generate devise:install
  ```

- [ ] 1.4: Configure CORS in `config/initializers/cors.rb`

- [ ] 1.5: Review Devise initializer at `config/initializers/devise.rb`

---

## Phase 2: User Model & Database ⏱️ ~20 mins

- [ ] 2.1: Generate User model with Devise
  ```bash
  rails generate devise User
  ```

- [ ] 2.2: Add custom fields to User migration
  ```ruby
  # Add to the migration file
  t.string :provider
  t.string :uid
  t.string :name
  t.string :avatar_url
  t.integer :sign_in_count, default: 0
  t.datetime :current_sign_in_at
  t.datetime :last_sign_in_at
  t.string :current_sign_in_ip
  t.string :last_sign_in_ip
  ```

- [ ] 2.3: Run migrations
  ```bash
  rails db:migrate
  ```

- [ ] 2.4: Update User model with validations and methods

---

## Phase 3: JWT Configuration ⏱️ ~30 mins

- [ ] 3.1: Generate JWT secret key
  ```bash
  bundle exec rake secret
  ```

- [ ] 3.2: Add JWT secret to credentials
  ```bash
  EDITOR="code --wait" rails credentials:edit
  # Add: jwt_secret_key: <generated_secret>
  ```

- [ ] 3.3: Create JWT denylist model
  ```bash
  rails generate model jwt_denylist jti:string:index exp:datetime
  rails db:migrate
  ```

- [ ] 3.4: Configure devise-jwt in `config/initializers/devise.rb`

- [ ] 3.5: Update User model to include JWT devise modules
  ```ruby
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :omniauthable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist
  ```

---

## Phase 4: Google OAuth Setup ⏱️ ~45 mins

- [ ] 4.1: Create Google OAuth credentials
  - Go to https://console.cloud.google.com/
  - Create new project or select existing
  - Enable Google+ API
  - Create OAuth 2.0 credentials
  - Add authorized redirect URIs:
    - `http://localhost:3000/users/auth/google_oauth2/callback` (dev)
    - `https://yourdomain.com/users/auth/google_oauth2/callback` (prod)

- [ ] 4.2: Add Google credentials to Rails credentials
  ```bash
  EDITOR="code --wait" rails credentials:edit
  ```
  ```yaml
  google:
    client_id: YOUR_CLIENT_ID
    client_secret: YOUR_CLIENT_SECRET
  ```

- [ ] 4.3: Configure OmniAuth in `config/initializers/devise.rb`

- [ ] 4.4: Add OmniAuth callback route in `config/routes.rb`

- [ ] 4.5: Create OmniAuth callbacks controller

- [ ] 4.6: Add `from_omniauth` method to User model

---

## Phase 5: API Authentication Controllers ⏱️ ~1 hour

- [ ] 5.1: Create API namespace structure
  ```bash
  mkdir -p app/controllers/api/v1/auth
  ```

- [ ] 5.2: Create API base controller
  - `app/controllers/api/v1/base_controller.rb`
  - Include authentication helpers
  - Handle JWT authentication

- [ ] 5.3: Create API Sessions controller
  - `app/controllers/api/v1/auth/sessions_controller.rb`
  - POST `/api/v1/auth/login` - Sign in (returns JWT)
  - DELETE `/api/v1/auth/logout` - Sign out (revoke JWT)

- [ ] 5.4: Create API Registrations controller
  - `app/controllers/api/v1/auth/registrations_controller.rb`
  - POST `/api/v1/auth/signup` - Create account (returns JWT)

- [ ] 5.5: Create API Google OAuth controller
  - `app/controllers/api/v1/auth/google_controller.rb`
  - POST `/api/v1/auth/google` - Exchange Google token for JWT

- [ ] 5.6: Create API current user controller
  - `app/controllers/api/v1/auth/users_controller.rb`
  - GET `/api/v1/auth/me` - Get current user info

---

## Phase 6: Web Authentication (Traditional) ⏱️ ~30 mins

- [ ] 6.1: Generate Devise views
  ```bash
  rails generate devise:views
  ```

- [ ] 6.2: Customize Devise views (optional)
  - Add Google OAuth button to sign in page
  - Style forms to match your design

- [ ] 6.3: Configure Devise routes in `config/routes.rb`

- [ ] 6.4: Add authentication to controllers
  ```ruby
  before_action :authenticate_user!
  ```

---

## Phase 7: Serializers & Response Formatting ⏱️ ~30 mins

- [ ] 7.1: Create User serializer for API responses
  ```bash
  mkdir -p app/serializers
  ```

- [ ] 7.2: Create `app/serializers/user_serializer.rb`

- [ ] 7.3: Create JWT response helper
  - Format: `{ user: {...}, token: "..." }`

---

## Phase 8: Routes Configuration ⏱️ ~20 mins

- [ ] 8.1: Configure API routes in `config/routes.rb`
  ```ruby
  namespace :api do
    namespace :v1 do
      namespace :auth do
        post 'login', to: 'sessions#create'
        delete 'logout', to: 'sessions#destroy'
        post 'signup', to: 'registrations#create'
        post 'google', to: 'google#create'
        get 'me', to: 'users#show'
      end
    end
  end
  ```

- [ ] 8.2: Configure web routes
  ```ruby
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }
  ```

---

## Phase 9: Testing ⏱️ ~2 hours

- [ ] 9.1: Create RSpec request specs for API auth
  - `spec/requests/api/v1/auth/sessions_spec.rb`
  - `spec/requests/api/v1/auth/registrations_spec.rb`
  - `spec/requests/api/v1/auth/google_spec.rb`
  - `spec/requests/api/v1/auth/users_spec.rb`

- [ ] 9.2: Create RSpec model specs
  - `spec/models/user_spec.rb`
  - `spec/models/jwt_denylist_spec.rb`

- [ ] 9.3: Create factories
  - `spec/factories/users.rb`
  - `spec/factories/jwt_denylists.rb`

- [ ] 9.4: Add authentication helpers for specs
  - `spec/support/auth_helpers.rb`
  - JWT token generation for tests
  - Login helpers

- [ ] 9.5: Test web authentication flows

---

## Phase 10: Security & Best Practices ⏱️ ~1 hour

- [ ] 10.1: Implement token refresh mechanism (optional but recommended)
  - Add refresh token endpoint
  - Store refresh tokens securely

- [ ] 10.2: Configure password requirements
  - Minimum length
  - Complexity rules

- [ ] 10.3: Add rate limiting for auth endpoints
  ```ruby
  gem 'rack-attack'
  ```

- [ ] 10.4: Implement account lockout after failed attempts
  - Enable `:lockable` in Devise

- [ ] 10.5: Add email confirmation (optional)
  - Enable `:confirmable` in Devise

- [ ] 10.6: Configure CORS properly for production

- [ ] 10.7: Set up secure token storage in frontend
  - Document best practices for frontend team

---

## Phase 11: Documentation ⏱️ ~45 mins

- [ ] 11.1: Create API authentication documentation
  - `doc/API_AUTHENTICATION.md`
  - Document all endpoints
  - Include curl examples
  - Add response formats

- [ ] 11.2: Create frontend integration guide
  - `doc/FRONTEND_AUTH_GUIDE.md`
  - How to handle tokens
  - How to refresh tokens
  - Error handling

- [ ] 11.3: Create deployment guide
  - Environment variables needed
  - Google OAuth configuration for production
  - Security checklist

- [ ] 11.4: Update main README with auth info

---

## Phase 12: Operations & Services Integration ⏱️ ~30 mins

- [ ] 12.1: Create auth operations
  - `app/operations/auth/register_user_operation.rb`
  - `app/operations/auth/authenticate_user_operation.rb`
  - `app/operations/auth/google_auth_operation.rb`

- [ ] 12.2: Create auth services
  - `app/services/auth/jwt_encoder_service.rb`
  - `app/services/auth/jwt_decoder_service.rb`
  - `app/services/auth/google_token_verifier_service.rb`

- [ ] 12.3: Refactor controllers to use operations

---

## Testing Checklist

### Web Authentication
- [ ] Sign up with email/password works
- [ ] Sign in with email/password works
- [ ] Sign in with Google works
- [ ] Sign out works
- [ ] Password reset works
- [ ] Remember me works

### API Authentication
- [ ] POST /api/v1/auth/signup returns JWT
- [ ] POST /api/v1/auth/login returns JWT
- [ ] POST /api/v1/auth/google returns JWT
- [ ] GET /api/v1/auth/me returns user with valid JWT
- [ ] DELETE /api/v1/auth/logout revokes JWT
- [ ] Invalid JWT returns 401
- [ ] Expired JWT returns 401
- [ ] Revoked JWT returns 401

### Security
- [ ] Passwords are encrypted
- [ ] JWT tokens expire
- [ ] Revoked tokens don't work
- [ ] CORS is configured correctly
- [ ] Rate limiting works
- [ ] Account lockout works (if enabled)

---

## Estimated Total Time: ~8-10 hours

## Priority Levels
- 🔴 Critical: Phases 1-5, 8 (Core authentication)
- 🟡 Important: Phases 6-7, 9 (Web UI & Testing)
- 🟢 Nice to have: Phases 10-12 (Security hardening & integration)

---

## Next Steps After Completion

1. Load test authentication endpoints
2. Set up monitoring for auth failures
3. Implement 2FA (optional)
4. Add social login for other providers (Facebook, GitHub, etc.)
5. Implement refresh token rotation
6. Add API key authentication for machine-to-machine auth

📚 Quick Reference
Key Files to Create:

config/initializers/cors.rb - CORS configuration
config/initializers/devise.rb - Devise & JWT config
app/models/jwt_denylist.rb - Token revocation
app/controllers/api/v1/base_controller.rb - API base
app/controllers/api/v1/auth/* - API auth controllers
app/controllers/users/omniauth_callbacks_controller.rb - OAuth callbacks
app/serializers/user_serializer.rb - API responses
doc/API_AUTHENTICATION.md - API docs

Environment Variables Needed:
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret
JWT_SECRET_KEY=your_jwt_secret
