# frozen_string_literal: true

module Api::V0::Roles
  class UpdateRoleOperation < BaseOperation
    contract do
      params do
        required(:role).hash do
          optional(:name).filled(:string)
          optional(:description).maybe(:string)
          optional(:permission_ids).maybe(:array)
        end
      end
    end

    def call(params, role_id, current_user)
      role = Role.find_by(id: role_id)
      return Failure(error: "Role not found") unless role

      # Update role using service
      result = Roles::UpdateService.call(
        role: role,
        params: params[:role],
        updated_by: current_user
      )

      return Failure(errors: result.error) unless result.success?

      Success(role: result.data, current_user: current_user)
    end
  end
end
