Apipie.configure do |config|
  config.app_name = "Bookturf API"
  config.app_info = "Sports venue booking platform API. All authenticated endpoints require a Bearer token in the Authorization header or an access_token cookie."
  config.api_base_url = "/api/v0"
  config.doc_base_url = "/apipie"
  config.api_controllers_matcher = Rails.root.join("app/controllers/api/**/*.rb").to_s
  config.default_version = "v0"
  config.show_all_examples = true
  config.validate = false

  config.authenticate = proc do
    authenticate_or_request_with_http_basic("Bookturf API Docs") do |username, password|
      username == "admin" && password == ENV.fetch("APIPIE_PASSWORD", "bookturf")
    end
  end if Rails.env.production?
end
