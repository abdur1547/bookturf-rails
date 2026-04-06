# frozen_string_literal: true

class CustomError < StandardError
  def message
    "custom error message"
  end
end
