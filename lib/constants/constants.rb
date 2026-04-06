# frozen_string_literal: true

module Constants
  SESSION_LIFETIME = 1.month
  REFRESH_TOKEN_LIFETIME = 3.months
  TOKEN_TYPE = "Bearer"
  DEFAULT_PER_PAGE = 50
  DEFAULT_PAGE = 1
  ORDER_DIRECTIONS = %w[asc ASC desc DESC].freeze
  API_DATE_FORMAT = "%d/%m/%Y"
  API_TIME_FORMAT = "%H:%M"
end
