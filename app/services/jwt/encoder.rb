# frozen_string_literal: true

module Jwt
  class Encoder < BaseService
    def call(user, exp = nil)
      jti = SecureRandom.hex
      exp ||= token_expiry

      access_token = JWT.encode(
          {
            user_id: user.id,
            jti: jti,
            iat: token_issued_at,
            exp: exp
          },
          ENV.fetch("SECRET_KEY_BASE", nil)
        )

      success([ access_token, jti, exp ])
    end

    private

    def token_expiry
      token_issued_at + Constants::SESSION_LIFETIME.to_i
    end

    def token_issued_at
      Time.now.utc.to_i
    end
  end
end
