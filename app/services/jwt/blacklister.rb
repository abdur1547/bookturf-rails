# frozen_string_literal: true

module Jwt
  class Blacklister < BaseService
    def call(jti:, user:)
      user.blacklisted_tokens.create!(
        jti:,
        exp: Time.now.utc
      )
    end
  end
end
