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

    resources :roles, only: API_ONLY_ROUTES
  end
end
