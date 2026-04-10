# frozen_string_literal: true

module Api::V0::Roles
  class GetRoleOperation < BaseOperation
    def call(role_id, current_user)
      role = Role.find_by(id: role_id)

      return Failure(error: "Role not found") unless role

      Success(role: role, current_user: current_user)
    end
  end
end
