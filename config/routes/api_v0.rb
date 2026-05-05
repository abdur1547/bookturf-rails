# frozen_string_literal: true

API_ONLY_ROUTES = [ :index, :show, :create, :update, :destroy ]

namespace :api do
  namespace :v0 do
    scope :auth do
      post :signup, to: "auth#signup"
      post :signin, to: "auth#signin"
      post :refresh, to: "auth#refresh"
      delete :signout, to: "auth#signout"
      post :reset_password, to: "auth#reset_password"
      post :verify_reset_otp, to: "auth#verify_reset_otp"
    end

    # User Management Endpoints
    scope :users do
      get :me, to: "users#show"
    end

    resources :users, only: %i[update destroy] do
      member do
        patch :change_password
      end

      collection do
        post :upload_avatar
      end
    end

    resources :roles, only: API_ONLY_ROUTES
    resources :venues, only: API_ONLY_ROUTES do
      member do
        get :availability
      end
    end
    resources :courts, only: API_ONLY_ROUTES
    resources :pricing_rules, only: API_ONLY_ROUTES

    resources :bookings, only: API_ONLY_ROUTES do
      collection do
        post :availability
      end

      member do
        patch :cancel
        patch :check_in
        patch :no_show
        patch :complete
        patch :reschedule
      end
    end
  end
end
