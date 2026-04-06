# frozen_string_literal: true

module Auth
  class UnauthorizedError < ::CustomError
    def message
      "user is unauthorized"
    end
  end
end
