# frozen_string_literal: true

module Api::V0::Auth
  class RefreshOperation < BaseOperation
    contract do
      params do
        required(:refresh_token).filled(:string)
      end
    end

    def call(params)
      @params = params
      yield validate_refresh_token
      issue_new_tokens
      Success(json_serialize)
    end

    private

    attr_reader :params, :user, :access_token, :refresh_token

    def validate_refresh_token
      refresh_token = RefreshToken.find_by_token(params[:refresh_token]) # rubocop:disable Rails/DynamicFindBy
      return Failure(:unauthorized) unless refresh_token

      @user = User.find_by(id: refresh_token.user_id)
      return Failure(:unauthorized) unless user

      Success()
    end

    def issue_new_tokens
      token_pair = Jwt::Issuer.call(user).data
      @access_token = token_pair[:access_token]
      @refresh_token = token_pair[:refresh_token].token
    end

    def json_serialize
      {
        access_token: "#{Constants::TOKEN_TYPE} #{access_token}",
        refresh_token: refresh_token
      }
    end
  end
end
