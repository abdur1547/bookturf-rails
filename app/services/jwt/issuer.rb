# frozen_string_literal: true

module Jwt
  class Issuer < BaseService
    def call(user)
      access_token = Jwt::Encoder.call(user).data.first
      refresh_token = user.refresh_tokens.create!
      success({ access_token:, refresh_token: })
    end
  end
end
