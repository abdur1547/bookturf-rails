# frozen_string_literal: true

module Api::V0::Auth
  class SignoutOperation < BaseOperation
    def call(current_user, decoded_token)
      current_user.blacklisted_tokens.create!(
        jti: decoded_token[:jti],
        exp: Time.now.utc
      )
      Success({})
    end
  end
end
