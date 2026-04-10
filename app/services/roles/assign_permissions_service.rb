# frozen_string_literal: true

module Roles
  class AssignPermissionsService < BaseService
    def call(role:, permission_ids:, assigned_by: nil)
      return failure("Cannot modify system roles") if role.system_role?

      permissions = Permission.where(id: permission_ids)
      if permissions.count != permission_ids.uniq.count
        return failure("Some permissions not found")
      end

      ActiveRecord::Base.transaction do
        permissions.each do |permission|
          role.add_permission(permission) unless role.has_permission?(permission.name)
        end

        # Log permission assignment
        log_permission_assignment(role, permissions, assigned_by) if assigned_by
      end

      success(role: role, permissions: permissions)
    rescue StandardError => e
      failure("Failed to assign permissions: #{e.message}")
    end

    private

    def log_permission_assignment(role, permissions, assigned_by)
      Rails.logger.info "Permissions #{permissions.pluck(:name).join(', ')} assigned to role #{role.id} by user #{assigned_by.id}"
    end
  end
end
