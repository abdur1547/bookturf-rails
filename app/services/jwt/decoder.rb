# frozen_string_literal: true

module Jwt
  class Decoder < BaseService
    attr_reader :access_token, :verify

    def call(access_token:, verify: true)
      decoded_token = JWT.decode(access_token, ENV.fetch("SECRET_KEY_BASE", nil), verify, verify_iat: true)[0]
      success(decoded_token.symbolize_keys)
    rescue JWT::ExpiredSignature, JWT::VerificationError, JWT::DecodeError => e
      failure(e)
    end
  end
end
