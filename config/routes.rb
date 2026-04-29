Rails.application.routes.draw do
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
