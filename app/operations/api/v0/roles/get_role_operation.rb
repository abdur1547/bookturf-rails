# frozen_string_literal: true

module Api::V0::Roles
  class GetRoleOperation < BaseOperation
    contract do
      params do
        required(:id).filled(:string)
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @role = Role.find_by(id: params[:id])
      return Failure(:not_found) unless @role

      return Failure(:forbidden) unless authorize?

      Success(role: @role, json: serialize)
    end

    private

    attr_reader :params, :current_user, :role

    def authorize?
      RolePolicy.new(current_user, role).show?
    end

    def serialize
      Api::V0::RoleBlueprint.render_as_hash(role)
    end
  end
end
