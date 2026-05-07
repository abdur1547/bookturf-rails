# frozen_string_literal: true

module Api::V0::Roles
  class DeleteRoleOperation < BaseOperation
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

      result = Roles::DeleteService.call(role: @role, deleted_by: current_user)
      return Failure(result.error) unless result.success?

      Success(role: @role, json: { message: "Role deleted successfully" })
    end

    private

    attr_reader :params, :current_user, :role

    def authorize?
      RolePolicy.new(current_user, role).destroy?
    end
  end
end
