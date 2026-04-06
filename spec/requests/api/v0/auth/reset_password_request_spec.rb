# frozen_string_literal: true

require 'rails_helper'
require 'benchmark'

RSpec.describe "Api::V0::Auth::ResetPasswordRequest", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user, email: "test@example.com", password: "oldpassword123", password_confirmation: "oldpassword123") }
  let(:headers) { { "Content-Type" => "application/json" } }

  describe "POST /api/v0/auth/reset_password" do
    let(:endpoint) { "/api/v0/auth/reset_password" }

    subject(:make_request) { post endpoint, params: params.to_json, headers: headers }

    context "with valid email of existing user" do
      let(:params) { { email: user.email } }

      before { user }  # ensure user exists

      it "returns success response" do
        make_request
        expect(response).to have_http_status(:ok)
      end

      it "matches success response structure" do
        make_request
        expect(response.parsed_body).to match(
          success: true,
          data: a_hash_including(
            message: a_string_including("If an account exists")
          )
        )
      end

      it "creates a password reset token" do
        expect { make_request }.to change(PasswordResetToken, :count).by(1)
      end

      it "sends an email to the user" do
        expect { make_request }.to have_enqueued_mail(PasswordResetMailer, :reset_password_otp)
      end

      it "invalidates existing unused tokens" do
        existing_token = create(:password_reset_token, user: user, used_at: nil)
        expect {
          make_request
        }.to change { existing_token.reload.used_at }.from(nil)
      end

      it "stores OTP code digest (not plain text)" do
        make_request
        token = PasswordResetToken.last
        expect(token.otp_code_digest).to be_present
        expect(token.otp_code_digest).not_to match(/^\d{6}$/)
      end

      it "sets expiry time to 15 minutes from now" do
        make_request
        token = PasswordResetToken.last
        expect(token.expires_at).to be_within(2.seconds).of(15.minutes.from_now)
      end

      context "JSON response structure" do
        before { make_request }
        include_examples "successful API response"
      end
    end

    context "with non-existent email" do
      let(:params) { { email: "nonexistent@example.com" } }

      before { make_request }

      include_examples "security response without user enumeration"

      it "does not create a password reset token" do
        expect { make_request }.not_to change(PasswordResetToken, :count)
      end

      it "does not send an email" do
        expect { make_request }.not_to have_enqueued_mail
      end
    end

    context "with case variations in email" do
      let(:params) { { email: user.email.upcase } }

      before { user }  # ensure user exists

      it "finds user case-insensitively" do
        expect { make_request }.to change(PasswordResetToken, :count).by(1)
      end

      it "sends email successfully" do
        expect { make_request }.to have_enqueued_mail(PasswordResetMailer, :reset_password_otp)
      end

      context "security response" do
        before { make_request }
        include_examples "security response without user enumeration"
      end
    end

    context "with email containing whitespace" do
      let(:params) { { email: "  #{user.email}  " } }

      before { user }  # ensure user exists

      it "strips whitespace and finds user" do
        expect { make_request }.to change(PasswordResetToken, :count).by(1)
      end

      it "sends email successfully" do
        expect { make_request }.to have_enqueued_mail(PasswordResetMailer, :reset_password_otp)
      end

      context "security response" do
        before { make_request }
        include_examples "security response without user enumeration"
      end
    end

    context "with mixed case and whitespace" do
      let(:params) { { email: "  #{user.email.upcase}  " } }

      it "normalizes email and finds user" do
        expect { make_request }.to change(PasswordResetToken, :count).by(1)
      end
    end

    context "with missing email parameter" do
      let(:params) { {} }

      before { make_request }

      include_examples "unprocessable entity response"

      it "includes email error" do
        expect(response.parsed_body[:errors]).to be_present
      end
    end

    context "with empty email" do
      let(:params) { { email: "" } }

      before { make_request }

      include_examples "unprocessable entity response"
    end

    context "with nil email" do
      let(:params) { { email: nil } }

      before { make_request }

      include_examples "unprocessable entity response"
    end

    context "with invalid email format" do
      let(:params) { { email: "notanemail" } }

      before { make_request }

      include_examples "security response without user enumeration"

      it "does not create token" do
        expect { make_request }.not_to change(PasswordResetToken, :count)
      end
    end

    context "when user already has multiple unused tokens" do
      let(:params) { { email: user.email } }

      before do
        create_list(:password_reset_token, 3, user: user, used_at: nil)
      end

      it "invalidates all existing unused tokens" do
        make_request
        expect(user.password_reset_tokens.where(used_at: nil).count).to eq(1)
      end

      it "keeps used tokens unchanged" do
        used_token = create(:password_reset_token, :used, user: user)
        make_request
        used_token.reload
        expect(used_token.used_at).to be_within(1.second).of(1.hour.ago)
      end
    end

    context "timing attack prevention" do
      it "takes similar time for existing and non-existing users" do
        existing_email = user.email
        non_existing_email = "nonexistent@example.com"

        time_for_existing = Benchmark.realtime do
          post endpoint, params: { email: existing_email }.to_json, headers: headers
        end

        time_for_non_existing = Benchmark.realtime do
          post endpoint, params: { email: non_existing_email }.to_json, headers: headers
        end

        # Both should take at least 100ms (our minimum sleep time)
        expect(time_for_existing).to be >= 0.1
        expect(time_for_non_existing).to be >= 0.1

        # Difference should be less than 1 second (accounting for random sleep)
        expect((time_for_existing - time_for_non_existing).abs).to be < 1
      end
    end
  end
end
