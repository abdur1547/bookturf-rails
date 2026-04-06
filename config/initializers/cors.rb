# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # In development, allow all origins
    # In production, replace with your frontend domain(s)
    if Rails.env.development?
      origins "*"

      resource "*",
        headers: :any,
        methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
        expose: [ "Authorization" ],
        credentials: false
    else
      origins ENV.fetch("CORS_ALLOWED_ORIGINS", "").split(",")

      resource "*",
        headers: :any,
        methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
        expose: [ "Authorization" ],
        credentials: true
    end
  end
end
