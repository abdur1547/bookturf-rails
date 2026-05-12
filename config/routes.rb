Rails.application.routes.draw do
  namespace :admin do
    resources :users
    resources :venues
    resources :courts
    resources :bookings
    resources :roles
    resources :permissions
    resources :role_permissions
    resources :venue_memberships
    resources :venue_operating_hours
    resources :venue_closures
    resources :court_closures
    resources :court_types
    resources :pricing_rules
    resources :notifications

    root to: "users#index"
  end
  # Authentication routes
  resource :session, only: %i[ new create destroy ]
  resources :passwords, param: :token, only: %i[ new create edit update ]
  resource :registration, only: %i[ new create ]

  # API v0 routes
  draw :api_v0

  get "up" => "rails/health#show", as: :rails_health_check

  root "welcome#index"

  mount MissionControl::Jobs::Engine, at: "/jobs"

  apipie
end
