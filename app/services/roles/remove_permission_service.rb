# frozen_string_literal: true

module Roles
  class RemovePermissionService < BaseService
    def call(role:, permission:, removed_by: nil)
      return failure("Cannot modify system roles") if role.system_role?

      unless role.has_permission?(permission.name)
        return failure("Permission not assigned to this role")
      end

      ActiveRecord::Base.transaction do
        role.remove_permission(permission)

        # Log permission removal
        log_permission_removal(role, permission, removed_by) if removed_by
      end

      success(message: "Permission removed successfully")
    rescue StandardError => e
      failure("Failed to remove permission: #{e.message}")
    end

    private

    def log_permission_removal(role, permission, removed_by)
      Rails.logger.info "Permission #{permission.name} removed from role #{role.id} by user #{removed_by.id}"
    end
  end
end
