# frozen_string_literal: true

module Roles
  class SyncPermissionsService < BaseService
    def call(role:, permission_ids:)
      permissions = Permission.where(id: permission_ids)
      if permissions.count != permission_ids.uniq.count
        return failure("Some permissions not found")
      end

      ActiveRecord::Base.transaction do
        role.permissions.clear
        permissions.each do |permission|
          role.add_permission(permission)
        end
      end

      success(role: role, permissions: permissions)
    rescue StandardError => e
      failure("Failed to sync permissions: #{e.message}")
    end
  end
end
