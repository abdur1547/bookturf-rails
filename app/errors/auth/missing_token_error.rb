# frozen_string_literal: true

module Auth
  class MissingTokenError < ::CustomError
    def message
      "JWT token is missing, JWT is required in headers of in params"
    end
  end
end
