# frozen_string_literal: true

module Api::V0::Auth
  class RequestPasswordResetOperation < BaseOperation
    contract do
      params do
        required(:email).filled(:string)
      end
    end

    def call(params)
      @params = params
      @email = params[:email].to_s.downcase.strip

      fetch_user
      send_reset_email if @user.present?

      random_sleep

      Success(success_message)
    end

    private

    attr_reader :params, :email, :user, :reset_token

    def fetch_user
      @user = User.find_by("LOWER(email) = ?", email)
    end

    def send_reset_email
      invalidate_existing_tokens
      @reset_token = user.password_reset_tokens.create!
      puts "OTP for user: #{user.email} is #{reset_token.otp_code}" if Rails.env == "development"
      PasswordResetMailer.reset_password_otp(user, reset_token.otp_code).deliver_later
    end

    def invalidate_existing_tokens
      user.password_reset_tokens
          .where(used_at: nil)
          .where("expires_at > ?", Time.current)
          .update_all(used_at: Time.current)
    end

    def random_sleep
      sleep(rand(100..300) / 1000.0)
    end

    def success_message
      {
        message: "If an account exists with this email, you will receive a password reset code shortly."
      }
    end
  end
end
