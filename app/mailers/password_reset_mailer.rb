# frozen_string_literal: true

class PasswordResetMailer < ApplicationMailer
  def reset_password_otp(user, otp_code)
    @user = user
    @otp_code = otp_code
    @expiry_minutes = PasswordResetToken::OTP_EXPIRY_DURATION.in_minutes.to_i

    mail(
      to: @user.email,
      subject: "Password Reset OTP Code"
    )
  end
end
