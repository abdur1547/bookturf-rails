# frozen_string_literal: true

module Roles
  class RemovePermissionService < BaseService
    def call(role:, permission:, removed_by: nil)
      unless role.permissions.include?(permission)
        return failure("Permission not assigned to this role")
      end

      ActiveRecord::Base.transaction do
        role.remove_permission(permission)

        log_permission_removal(role, permission, removed_by) if removed_by
      end

      success(message: "Permission removed successfully")
    rescue StandardError => e
      failure("Failed to remove permission: #{e.message}")
    end

    private

    def log_permission_removal(role, permission, removed_by)
      Rails.logger.info "Permission #{permission.action}:#{permission.resource} removed from role #{role.id} by user #{removed_by.id}"
    end
  end
end
