# frozen_string_literal: true

# Capybara configuration for system tests
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
  end
end

# Set Capybara server host and port for consistency
Capybara.server_host = 'localhost'
Capybara.server_port = 3001
