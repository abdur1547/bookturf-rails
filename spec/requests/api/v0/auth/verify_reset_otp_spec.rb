# # frozen_string_literal: true

# require 'rails_helper'

# RSpec.describe "Api::V0::Auth::VerifyResetOtp", type: :request do
#   include ActiveJob::TestHelper

#   let(:user) { create(:user, email: "test@example.com", password: "oldpassword123", password_confirmation: "oldpassword123") }
#   let(:headers) { { "Content-Type" => "application/json" } }

#   describe "POST /api/v0/auth/verify_reset_otp" do
#     let(:endpoint) { "/api/v0/auth/verify_reset_otp" }
#     let(:otp_code) { "123456" }
#     let(:new_password) { "newpassword123" }
#     let(:reset_token) do
#       token = user.password_reset_tokens.create!
#       token.update_columns(
#         otp_code_digest: Digest::SHA256.hexdigest(otp_code),
#         expires_at: 15.minutes.from_now
#       )
#       token
#     end

#     subject(:make_request) { post endpoint, params: params.to_json, headers: headers }

#     context "with valid OTP and new password" do
#       let(:params) do
#         {
#           email: user.email,
#           otp_code: otp_code,
#           password: new_password
#         }
#       end

#       before { reset_token }

#       it "returns success response" do
#         make_request
#         expect(response).to have_http_status(:ok)
#       end

#       it "matches success response structure" do
#         make_request
#         expect(response.parsed_body).to match(
#           success: true,
#           data: a_hash_including(
#             message: a_string_including("successfully reset")
#           )
#         )
#       end

#       it "updates the user's password" do
#         make_request
#         user.reload
#         expect(user.authenticate(new_password)).to be_truthy
#         expect(user.authenticate("oldpassword123")).to be_falsey
#       end

#       it "marks the token as used" do
#         make_request
#         reset_token.reload
#         expect(reset_token.used_at).not_to be_nil
#         expect(reset_token.used_at).to be_within(2.seconds).of(Time.current)
#       end

#       it "invalidates all other tokens for the user" do
#         # Use a specific OTP for this test to avoid conflicts
#         unique_otp = "555555"

#         # Create first token with the OTP we'll use
#         token_to_use = user.password_reset_tokens.create!
#         token_to_use.update_columns(
#           otp_code_digest: Digest::SHA256.hexdigest(unique_otp),
#           expires_at: 15.minutes.from_now,
#           used_at: nil
#         )

#         # Create another token with a different OTP
#         other_token = user.password_reset_tokens.create!
#         other_token.update_columns(
#           otp_code_digest: Digest::SHA256.hexdigest("999999"),
#           expires_at: 15.minutes.from_now,
#           used_at: nil
#         )

#         # Note: The before block also creates a token, so we have 3 total
#         expect(user.password_reset_tokens.count).to eq(3)

#         # Make request with our unique OTP
#         unique_params = {
#           email: user.email,
#           otp_code: unique_otp,
#           password: new_password
#         }
#         post endpoint, params: unique_params.to_json, headers: headers
#         expect(response).to have_http_status(:ok)

#         # Reload both tokens to see the updated state
#         token_to_use.reload
#         other_token.reload

#         # The token we used should be marked as used
#         expect(token_to_use.used_at).not_to be_nil

#         # The other token should also be marked as used (invalidated)
#         expect(other_token.used_at).not_to be_nil
#       end

#       it "allows user to sign in with new password" do
#         make_request
#         signin_params = { email: user.email, password: new_password }
#         post "/api/v0/auth/signin", params: signin_params.to_json, headers: headers
#         expect(response).to have_http_status(:ok)
#       end

#       it "does not allow sign in with old password" do
#         make_request
#         signin_params = { email: user.email, password: "oldpassword123" }
#         post "/api/v0/auth/signin", params: signin_params.to_json, headers: headers
#         expect(response).to have_http_status(:forbidden)
#       end

#       include_examples "successful API response" do
#         before { make_request }
#       end
#     end

#     context "with case variations in email" do
#       let(:params) do
#         {
#           email: user.email.upcase,
#           otp_code: otp_code,
#           password: new_password
#         }
#       end

#       before { reset_token }

#       it "finds user and resets password" do
#         make_request
#         expect(response).to have_http_status(:ok)
#         user.reload
#         expect(user.authenticate(new_password)).to be_truthy
#       end
#     end

#     context "with invalid OTP code" do
#       let(:params) do
#         {
#           email: user.email,
#           otp_code: "999999",
#           password: new_password
#         }
#       end

#       before { reset_token }

#       include_examples "invalid OTP scenario"
#     end

#     context "with expired OTP token" do
#       let(:params) do
#         {
#           email: user.email,
#           otp_code: otp_code,
#           password: new_password
#         }
#       end

#       before do
#         reset_token
#         reset_token.update_column(:expires_at, 1.hour.ago)
#       end

#       include_examples "invalid OTP scenario"
#     end

#     context "with already used OTP token" do
#       let(:params) do
#         {
#           email: user.email,
#           otp_code: otp_code,
#           password: new_password
#         }
#       end

#       before do
#         reset_token
#         reset_token.update_column(:used_at, 1.hour.ago)
#       end

#       include_examples "invalid OTP scenario"
#     end

#     context "with OTP belonging to different user" do
#       let(:other_user) { create(:user, email: "other@example.com") }
#       let(:other_user_token) do
#         token = other_user.password_reset_tokens.create!
#         token.update_columns(
#           otp_code_digest: Digest::SHA256.hexdigest("654321"),
#           expires_at: 15.minutes.from_now
#         )
#         token
#       end

#       let(:params) do
#         {
#           email: user.email,
#           otp_code: "654321",
#           password: new_password
#         }
#       end

#       before { other_user_token }

#       include_examples "invalid OTP scenario"

#       it "does not update other user's password" do
#         make_request
#         other_user.reload
#         expect(other_user.authenticate("password123")).to be_truthy
#       end
#     end

#     context "with non-existent user" do
#       let(:params) do
#         {
#           email: "nonexistent@example.com",
#           otp_code: otp_code,
#           password: new_password
#         }
#       end

#       include_examples "invalid OTP scenario"
#     end

#     context "with short password" do
#       let(:params) do
#         {
#           email: user.email,
#           otp_code: otp_code,
#           password: "123"
#         }
#       end

#       before { reset_token }

#       include_examples "validation error scenario", :password
#     end

#     context "with blank password" do
#       let(:params) do
#         {
#           email: user.email,
#           otp_code: otp_code,
#           password: ""
#         }
#       end

#       before { reset_token }

#       include_examples "validation error scenario", :password
#     end

#     context "with invalid OTP format" do
#       context "with only 5 digits" do
#         let(:params) do
#           {
#             email: user.email,
#             otp_code: "12345",
#             password: new_password
#           }
#         end

#         include_examples "validation error scenario", :otp_code
#       end

#       context "with 7 digits" do
#         let(:params) do
#           {
#             email: user.email,
#             otp_code: "1234567",
#             password: new_password
#           }
#         end

#         include_examples "validation error scenario", :otp_code
#       end
#     end

#     context "with non-numeric OTP" do
#       let(:params) do
#         {
#           email: user.email,
#           otp_code: "abcdef",
#           password: new_password
#         }
#       end

#       include_examples "validation error scenario", :otp_code
#     end

#     context "with special characters in OTP" do
#       let(:params) do
#         {
#           email: user.email,
#           otp_code: "12@45#",
#           password: new_password
#         }
#       end

#       include_examples "validation error scenario", :otp_code
#     end

#     context "with missing required fields" do
#       context "missing email" do
#         let(:params) do
#           {
#             otp_code: otp_code,
#             password: new_password
#           }
#         end

#         include_examples "validation error scenario", :email
#       end

#       context "missing otp_code" do
#         let(:params) do
#           {
#             email: user.email,
#             password: new_password
#           }
#         end

#         include_examples "validation error scenario", :otp_code
#       end

#       context "missing password" do
#         let(:params) do
#           {
#             email: user.email,
#             otp_code: otp_code
#           }
#         end

#         before { reset_token }

#         include_examples "validation error scenario", :password
#       end
#     end

#     context "with nil values" do
#       context "nil email" do
#         let(:params) do
#           {
#             email: nil,
#             otp_code: otp_code,
#             password: new_password
#           }
#         end

#         include_examples "validation error scenario", :email
#       end

#       context "nil otp_code" do
#         let(:params) do
#           {
#             email: user.email,
#             otp_code: nil,
#             password: new_password
#           }
#         end

#         include_examples "validation error scenario", :otp_code
#       end
#     end

#     context "attempting to reuse OTP after successful reset" do
#       let(:params) do
#         {
#           email: user.email,
#           otp_code: otp_code,
#           password: new_password
#         }
#       end

#       before { reset_token }

#       it "fails on second attempt" do
#         # First attempt - should succeed
#         post endpoint, params: params.to_json, headers: headers
#         expect(response).to have_http_status(:ok)

#         # Second attempt with same OTP - should fail
#         post endpoint, params: params.to_json, headers: headers
#         expect(response).to have_http_status(:unprocessable_entity)
#         expect(response.parsed_body[:errors].first).to include("Invalid or expired")
#       end

#       it "does not allow password reset with different password on second attempt" do
#         # First reset
#         make_request
#         user.reload
#         expect(user.authenticate(new_password)).to be_truthy

#         # Try to reset again with different password
#         different_password = "differentpassword456"
#         post endpoint, params: {
#           email: user.email,
#           otp_code: otp_code,
#           password: different_password
#         }.to_json, headers: headers

#         expect(response).to have_http_status(:unprocessable_entity)
#         user.reload
#         expect(user.authenticate(new_password)).to be_truthy
#         expect(user.authenticate(different_password)).to be_falsey
#       end
#     end

#     context "with concurrent token usage" do
#       let(:params) do
#         {
#           email: user.email,
#           otp_code: otp_code,
#           password: new_password
#         }
#       end

#       before { reset_token }

#       it "ensures only one token can be used successfully" do
#         # First request should succeed
#         make_request
#         expect(response).to have_http_status(:ok)

#         # Concurrent request with same credentials should fail
#         post endpoint, params: params.to_json, headers: headers
#         expect(response).to have_http_status(:unprocessable_entity)
#       end
#     end

#     context "with multiple valid tokens" do
#       let(:params) do
#         {
#           email: user.email,
#           otp_code: otp_code,
#           password: new_password
#         }
#       end

#       let(:older_token) do
#         token = user.password_reset_tokens.create!
#         token.update_columns(
#           otp_code_digest: Digest::SHA256.hexdigest(otp_code),
#           expires_at: 15.minutes.from_now,
#           created_at: 10.minutes.ago
#         )
#         token
#       end

#       before do
#         older_token
#         reset_token  # newer token with same OTP
#       end

#       it "uses the most recent token" do
#         make_request
#         expect(response).to have_http_status(:ok)
#         reset_token.reload
#         expect(reset_token.used_at).not_to be_nil
#       end
#     end

#     context "edge cases" do
#       context "with extremely long password" do
#         let(:long_password) { "a" * 1000 }
#         let(:params) do
#           {
#             email: user.email,
#             otp_code: otp_code,
#             password: long_password
#           }
#         end

#         before { reset_token }

#         it "handles long password appropriately" do
#           make_request
#           # This should either succeed or fail with validation error
#           expect([ 200, 422 ]).to include(response.status)
#         end
#       end

#       context "with whitespace in OTP" do
#         let(:params) do
#           {
#             email: user.email,
#             otp_code: " 123456 ",
#             password: new_password
#           }
#         end

#         before { reset_token }

#         it "handles whitespace appropriately" do
#           make_request
#           # Implementation may strip whitespace or reject it
#           expect(response).to have_http_status(:unprocessable_entity).or have_http_status(:ok)
#         end
#       end
#     end
#   end
# end
