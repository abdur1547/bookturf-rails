# frozen_string_literal: true

module Api::V0::Auth
  class VerifyOtpAndResetPasswordOperation < BaseOperation
    contract do
      params do
        required(:email).filled(:string)
        required(:otp_code).filled(:string)
        required(:password).filled(:string)
      end

      rule(:otp_code) do
        key.failure("must be a 6-digit code") unless value.match?(/^\d{6}$/)
      end

      rule(:password) do
        key.failure("must be at least 6 characters") if value.length < 6
      end
    end

    def call(params)
      @params = params
      @email = params[:email].to_s.downcase.strip
      @otp_code = params[:otp_code].to_s.strip

      yield fetch_user
      yield verify_otp_token
      yield check_token_validity
      yield update_password
      mark_token_as_used

      Success(success_message)
    end

    private

    attr_reader :params, :email, :otp_code, :user, :reset_token

    def fetch_user
      @user = User.find_by("LOWER(email) = ?", email)
      return Failure(error_message) unless user

      Success()
    end

    def verify_otp_token
      @reset_token = PasswordResetToken.find_valid_by_otp(otp_code)

      # Security: Check if token belongs to the user making the request
      return Failure(error_message) unless reset_token&.user_id == user.id

      Success()
    end

    def check_token_validity
      return Failure(error_message) unless reset_token.valid_token?

      Success()
    end

    def update_password
      if user.update(
        password: params[:password],
        password_confirmation: params[:password]
      )
        Success()
      else
        Failure(user.errors)
      end
    end

    def mark_token_as_used
      reset_token.mark_as_used!

      # Also invalidate all other tokens for this user
      # Use direct model query to avoid association cache issues
      PasswordResetToken
          .where(user_id: user.id)
          .where.not(id: reset_token.id)
          .where(used_at: nil)
          .update_all(used_at: Time.current)
    end

    def success_message
      {
        message: "Your password has been successfully reset. You can now sign in with your new password."
      }
    end

    def error_message
      "Invalid or expired OTP code. Please request a new password reset."
    end
  end
end
