# frozen_string_literal: true

module Roles
  class AssignPermissionsService < BaseService
    def call(role:, permission_ids:, assigned_by: nil)
      permissions = Permission.where(id: permission_ids)
      if permissions.count != permission_ids.uniq.count
        return failure("Some permissions not found")
      end

      ActiveRecord::Base.transaction do
        permissions.each do |permission|
          role.add_permission(permission) unless role.permissions.include?(permission)
        end

        log_permission_assignment(role, permissions, assigned_by) if assigned_by
      end

      success(role: role, permissions: permissions)
    rescue StandardError => e
      failure("Failed to assign permissions: #{e.message}")
    end

    private

    def log_permission_assignment(role, permissions, assigned_by)
      labels = permissions.map { |p| "#{p.action}:#{p.resource}" }.join(", ")
      Rails.logger.info "Permissions #{labels} assigned to role #{role.id} by user #{assigned_by.id}"
    end
  end
end
