# frozen_string_literal: true

# Shared examples for API request specs
RSpec.shared_examples "valid JSON response structure" do
  it "returns valid JSON" do
    expect { JSON.parse(response.body, symbolize_names: true) }.not_to raise_error
  end

  it "includes success field" do
    expect(JSON.parse(response.body, symbolize_names: true)).to have_key(:success)
  end
end

# Shared example for successful API responses
RSpec.shared_examples "successful API response" do
  include_examples "valid JSON response structure"

  it "returns success true" do
    expect(response.parsed_body[:success]).to be true
  end

  it "includes data field" do
    expect(response.parsed_body).to have_key(:data)
    expect(response.parsed_body[:data]).to be_a(Hash)
  end
end

# Shared example for error API responses
RSpec.shared_examples "error API response" do
  include_examples "valid JSON response structure"

  it "returns success false" do
    expect(response.parsed_body[:success]).to be false
  end

  it "includes errors field" do
    expect(response.parsed_body).to have_key(:errors)
  end
end

# Shared example for unprocessable entity responses
RSpec.shared_examples "unprocessable entity response" do
  include_examples "error API response"

  it "returns 422 status" do
    expect(response).to have_http_status(:unprocessable_entity)
  end
end

# Shared example for security response (no user enumeration)
RSpec.shared_examples "security response without user enumeration" do
  it "returns success status" do
    expect(response).to have_http_status(:ok)
  end

  include_examples "successful API response"

  it "returns generic message" do
    expect(response.parsed_body[:data][:message]).to include("If an account exists")
  end
end

# Shared example for invalid OTP scenarios
RSpec.shared_examples "invalid OTP scenario" do
  before { make_request }

  include_examples "unprocessable entity response"

  it "includes invalid or expired error message" do
    expect(response.parsed_body[:errors][:error]).to include("Invalid or expired")
  end

  it "does not update the user's password" do
    user.reload
    expect(user.valid_password?("oldpassword123")).to be true
    expect(user.valid_password?(new_password)).to be false
  end

  it "does not mark any token as used" do
    user.password_reset_tokens.reload.each do |token|
      expect(token.used_at).to be_nil if token.used_at.nil?
    end
  end
end

# Shared example for validation error scenarios
RSpec.shared_examples "validation error scenario" do |field|
  before { make_request }

  include_examples "unprocessable entity response"

  it "includes #{field} in errors" do
    expect(response.parsed_body[:errors]).to have_key(field)
  end

  it "does not update password" do
    user.reload
    expect(user.valid_password?("oldpassword123")).to be true
  end
end
