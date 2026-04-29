# frozen_string_literal: true

module Api::V0
  class AuthController < ApiController
    include ActionController::Cookies

    skip_before_action :authenticate_user!, only: %i[signup signin refresh reset_password verify_reset_otp]

    resource_description do
      resource_id "Authentication"
      api_versions "v0"
      short "User authentication — sign up, sign in, token refresh, sign out, and password reset"
      description <<~DESC
        All successful auth responses set `access_token` and `refresh_token` as HttpOnly cookies
        in addition to returning the tokens in the JSON body and the `Authorization` response header.
      DESC
    end

    api :POST, "/auth/signup", "Register a new user account"
    param :full_name, String, required: true, desc: "User's full name"
    param :email, String, required: true, desc: "Unique email address"
    param :password, String, required: true, desc: "Password (minimum 6 characters)"
    returns code: 200, desc: "User created successfully" do
      property :success, [ true ], desc: "Always true on success"
      property :data, Hash, desc: "Response payload" do
        property :access_token, String, desc: "Bearer JWT access token"
        property :refresh_token, String, desc: "Opaque refresh token string"
        property :user, Hash, desc: "Created user object"
      end
    end
    error code: 422, desc: "Validation error (invalid email, duplicate account, short password)"
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

    api :POST, "/auth/signin", "Authenticate with email and password"
    param :email, String, required: true, desc: "Registered email address"
    param :password, String, required: true, desc: "Account password"
    returns code: 200, desc: "Authenticated successfully" do
      property :success, [ true ], desc: "Always true on success"
      property :data, Hash, desc: "Response payload" do
        property :access_token, String, desc: "Bearer JWT access token"
        property :refresh_token, String, desc: "Opaque refresh token string"
        property :user, Hash, desc: "Authenticated user object"
      end
    end
    error code: 401, desc: "Invalid email or password"
    def signin
      result = Api::V0::Auth::SigninOperation.call(params.to_unsafe_h)
      if result.success
        set_auth_cookies(result.value[:access_token], result.value[:refresh_token])
        response.set_header("Authorization", result.value[:access_token])
        success_response(result.value)
      else
        unauthorized_response
      end
    end

    api :POST, "/auth/refresh", "Issue a new token pair using a refresh token"
    description <<~DESC
      The refresh token is read from the `refresh_token` cookie automatically.
      You may also pass it explicitly in the request body as a fallback.
    DESC
    param :refresh_token, String, required: false, desc: "Refresh token (falls back to cookie)"
    returns code: 200, desc: "Tokens refreshed successfully" do
      property :success, [ true ], desc: "Always true on success"
      property :data, Hash, desc: "Response payload" do
        property :access_token, String, desc: "New Bearer JWT access token"
        property :refresh_token, String, desc: "New opaque refresh token string"
      end
    end
    error code: 401, desc: "Refresh token missing, invalid, or expired"
    def refresh
      result = Api::V0::Auth::RefreshOperation.call(refresh_params)
      if result.success
        set_auth_cookies(result.value[:access_token], result.value[:refresh_token])
        response.set_header("Authorization", result.value[:access_token])
        success_response(result.value)
      else
        unauthorized_response
      end
    end

    api :DELETE, "/auth/signout", "Invalidate the current session and clear auth cookies"
    header "Authorization", "Bearer <access_token>", required: true
    returns code: 200, desc: "Signed out successfully" do
      property :success, [ true ], desc: "Always true on success"
      property :data, Hash, desc: "Response payload" do
        property :message, String, desc: "Confirmation message"
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 422, desc: "Sign-out operation failed"
    def signout
      result = Api::V0::Auth::SignoutOperation.call(current_user, decoded_token)
      if result.success
        cookies.delete(:access_token, domain: :all, path: "/")
        cookies.delete(:refresh_token, domain: :all, path: "/")

        success_response({ message: "Signed out successfully" })
      else
        unprocessable_entity(result.errors)
      end
    end

    api :POST, "/auth/reset_password", "Request a password reset OTP via email"
    description <<~DESC
      Always returns a success response regardless of whether the email exists,
      to prevent user enumeration attacks.
    DESC
    param :email, String, required: true, desc: "Email address of the account to reset"
    returns code: 200, desc: "Reset email dispatched (or silently skipped if account not found)" do
      property :success, [ true ], desc: "Always true on success"
      property :data, Hash, desc: "Response payload" do
        property :message, String, desc: "Generic confirmation message"
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

    api :POST, "/auth/verify_reset_otp", "Verify OTP and set a new password"
    param :email, String, required: true, desc: "Email address of the account"
    param :otp_code, String, required: true, desc: "6-digit OTP code received via email"
    param :password, String, required: true, desc: "New password (minimum 6 characters)"
    returns code: 200, desc: "Password reset successfully" do
      property :success, [ true ], desc: "Always true on success"
      property :data, Hash, desc: "Response payload" do
        property :message, String, desc: "Confirmation message"
      end
    end
    error code: 422, desc: "Invalid or expired OTP code, or password too short"
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
        secure: true,
        expires: Constants::SESSION_LIFETIME.from_now
      }
      cookies[:refresh_token] = {
        value: refresh_token,
        httponly: true,
        secure: true,
        expires: Constants::REFRESH_TOKEN_LIFETIME.from_now
      }
    end

    def refresh_params
      {
        refresh_token: request.cookies["refresh_token"] || params[:refresh_token]
      }
    end
  end
end
