# frozen_string_literal: true

module Api::V0
  class AuthController < ApiController
    include ActionController::Cookies

    skip_before_action :authenticate_user!, only: %i[signup signin refresh reset_password verify_reset_otp]

    def signup
      result = Api::V0::Auth::SignupOperation.call(params.to_unsafe_h)
      if result.success
        set_auth_cookies(result.value[:access_token], result.value[:refresh_token])
        response.set_header("Authorization", result.value[:access_token])
        success_response(result.value)
      else
        unprocessable_entity(result.errors)
      end
    end

    def signin
      result = Api::V0::Auth::SigninOperation.call(params.to_unsafe_h)
      if result.success
        set_auth_cookies(result.value[:access_token], result.value[:refresh_token])
        response.set_header("Authorization", result.value[:access_token])
        success_response(result.value)
      else
        unprocessable_entity(result.errors)
      end
    end

    def refresh
      result = Api::V0::Auth::RefreshOperation.call(refresh_params)
      if result.success
        set_auth_cookies(result.value[:access_token], result.value[:refresh_token])
        response.set_header("Authorization", result.value[:access_token])
        success_response(result.value)
      else
        unprocessable_entity(result.errors)
      end
    end

    def signout
      result = Api::V0::Auth::SignoutOperation.call(current_user, decoded_token)
      if result.success
        success_response({})
      else
        unprocessable_entity(result.errors)
      end
    end

    def reset_password
      result = Api::V0::Auth::RequestPasswordResetOperation.call(params.to_unsafe_h)
      if result.success
        success_response(result.value)
      else
        unprocessable_entity(result.errors)
      end
    end

    def verify_reset_otp
      result = Api::V0::Auth::VerifyOtpAndResetPasswordOperation.call(params.to_unsafe_h)
      if result.success
        success_response(result.value)
      else
        unprocessable_entity(result.errors)
      end
    end

    private

    def set_auth_cookies(access_token, refresh_token)
      cookies[:access_token] = {
        value: access_token,
        httponly: true,
        secure: Rails.env.production?
      }
      cookies[:refresh_token] = {
        value: refresh_token,
        httponly: true,
        secure: Rails.env.production?
      }
    end

    def refresh_params
      {
        refresh_token: request.cookies["refresh_token"] || params[:refresh_token]
      }
    end
  end
end
