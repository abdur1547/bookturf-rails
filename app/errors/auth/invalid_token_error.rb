# frozen_string_literal: true

module Auth
  class InvalidTokenError < ::CustomError
    def message
      "jwt token is invalid"
    end
  end
end
