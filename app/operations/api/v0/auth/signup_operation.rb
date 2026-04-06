# frozen_string_literal: true

module Api::V0::Auth
  class SignupOperation < BaseOperation
    contract do
      params do
        required(:name).filled(:string)
        required(:email).filled(:string)
        required(:password).filled(:string)
        required(:password_confirmation).filled(:string)
      end
    end

    def call(params)
      @params = params

      yield validate_email
      yield create_user
      issue_new_tokens
      Success(json_serialize)
    end

    private

    attr_reader :params, :user, :access_token, :refresh_token

    def validate_email
      email_regex = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
      email_regex.match?(params[:email]) ? Success() : Failure(error_message(:email, "invalid email address"))
    end

    def create_user
      @user = User.new(email: params[:email],
                        password: params[:password],
                        password_confirmation: params[:password_confirmation],
                        name: params[:name])
      return Success() if user.save

      Failure(user.errors.to_hash)
    end

    def issue_new_tokens
      token_pair = Jwt::Issuer.call(user).data
      @access_token = token_pair[:access_token]
      @refresh_token = token_pair[:refresh_token].token
    end

    def json_serialize
      Api::V0::UserBlueprint.render_as_hash(user).merge(token_pair)
    end

    def token_pair
      {
        access_token: "#{Constants::TOKEN_TYPE} #{access_token}",
        refresh_token:
      }
    end
  end
end
