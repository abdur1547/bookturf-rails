

# Gem Stack
## Authentication
gem 'devise', '~> 4.9'                    # Core authentication
gem 'devise-jwt', '~> 0.11'               # JWT support for API
gem 'omniauth-google-oauth2', '~> 1.1'   # Google OAuth
gem 'omniauth-rails_csrf_protection'     # CSRF protection for OAuth

## JWT token management
gem 'jsonapi-serializer'                  # API response serialization (optional but recommended)

## CORS for API requests
gem 'rack-cors'                           # Cross-origin requests

# Architecture Overview
┌─────────────────────────────────────────────────────────────┐
│                     Rails Application                        │
├─────────────────────┬───────────────────────────────────────┤
│   Web Interface     │         REST API                      │
│   (Session-based)   │         (JWT-based)                   │
├─────────────────────┼───────────────────────────────────────┤
│                     │                                       │
│ • Session cookies   │ • JWT in Authorization header         │
│ • Devise views      │ • /api/v1/auth/* endpoints           │
│ • Google OAuth      │ • Token refresh mechanism             │
│ • Email/Password    │ • Email/Password (returns JWT)        │
│                     │ • Google OAuth (returns JWT)          │
└─────────────────────┴───────────────────────────────────────┘
                              ↓
                    ┌─────────────────┐
                    │  Devise + User  │
                    │     Model       │
                    └─────────────────┘

How It Works
For Web Interface (Traditional Rails):

User visits /users/sign_in or /users/auth/google_oauth2
Devise handles authentication with sessions
Session cookie stored in browser
Standard Rails authentication flow
For API (Frontend SPA):

POST to /api/v1/auth/login with credentials
Returns JWT token in response
Frontend stores token (localStorage/memory)
Sends token in Authorization: Bearer <token> header
Token validated on each request
For Google OAuth (API):

Frontend gets Google token from Google's OAuth flow
POST Google token to /api/v1/auth/google
Backend verifies token with Google
Returns JWT token for your app