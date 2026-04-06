# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :google_oauth2

  # Handles the callback from Google OAuth2
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

  # Handle OmniAuth failure
  def failure
    redirect_to root_path, alert: "Authentication failed, please try again."
  end

  protected

  # Extract auth parameters from OmniAuth
  def auth_params
    request.env["omniauth.auth"]
  end

  # The path used when OmniAuth fails
  def after_omniauth_failure_path_for(scope)
    new_user_session_path
  end
end
