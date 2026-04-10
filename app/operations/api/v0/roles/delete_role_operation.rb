# frozen_string_literal: true

module Api::V0::Roles
  class DeleteRoleOperation < BaseOperation
    def call(role_id, current_user)
      role = Role.find_by(id: role_id)
      return Failure(error: "Role not found") unless role

      # Delete role using service
      result = Roles::DeleteService.call(
        role: role,
        deleted_by: current_user
      )

      return Failure(error: result.error) unless result.success?

      Success(message: "Role deleted successfully", current_user: current_user)
    end
  end
end
