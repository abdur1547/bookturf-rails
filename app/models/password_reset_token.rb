# frozen_string_literal: true

class PasswordResetToken < ApplicationRecord
  belongs_to :user

  before_create :set_otp_digest

  attr_accessor :otp_code

  # OTP is valid for 15 minutes
  OTP_EXPIRY_DURATION = 15.minutes

  # Find a valid token by OTP code
  def self.find_valid_by_otp(otp_code)
    otp_digest = Digest::SHA256.hexdigest(otp_code)
    where(otp_code_digest: otp_digest)
      .where("expires_at > ?", Time.current)
      .where(used_at: nil)
      .first
  end

  # Check if token is expired
  def expired?
    expires_at < Time.current
  end

  # Check if token has been used
  def used?
    used_at.present?
  end

  # Mark token as used
  def mark_as_used!
    update!(used_at: Time.current)
  end

  # Check if token is valid (not expired and not used)
  def valid_token?
    !expired? && !used?
  end

  private

  def set_otp_digest
    # Generate a 6-digit OTP code
    self.otp_code = SecureRandom.random_number(900_000) + 100_000
    self.otp_code = otp_code.to_s
    self.otp_code_digest = Digest::SHA256.hexdigest(otp_code)
    self.expires_at = Time.current + OTP_EXPIRY_DURATION
  end
end
