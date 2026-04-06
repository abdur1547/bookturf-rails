# frozen_string_literal: true

require "oj"

Oj::Rails.mimic_JSON
Blueprinter.configure do |config|
  config.generator = Oj
end
