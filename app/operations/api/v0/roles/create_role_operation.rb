# frozen_string_literal: true

module Api::V0::Roles
  class CreateRoleOperation < BaseOperation
    contract do
      params do
        required(:role).hash do
          required(:name).filled(:string)
          optional(:description).maybe(:string)
          optional(:permission_ids).maybe(:array)
        end
      end
    end

    def call(params, current_user)
      role_params = params[:role]

      # Create role using service
      result = Roles::CreateService.call(
        params: role_params.except(:permission_ids),
        created_by: current_user
      )

      return Failure(errors: result.error) unless result.success?

      role = result.data

      # Assign permissions if provided
      if role_params[:permission_ids].present?
        assign_result = Roles::AssignPermissionsService.call(
          role: role,
          permission_ids: role_params[:permission_ids],
          assigned_by: current_user
        )

        return Failure(errors: assign_result.error) unless assign_result.success?
      end

      Success(role: role, current_user: current_user)
    end
  end
end
