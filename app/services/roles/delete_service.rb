# frozen_string_literal: true

module Roles
  class DeleteService < BaseService
    def call(role:, deleted_by: nil)
      return failure("Cannot delete system roles") if role.system_role?
      return failure("Cannot delete role with assigned users") if role.users.any?

      ActiveRecord::Base.transaction do
        role_id = role.id
        role.destroy!

        # Log deletion in audit trail
        log_role_deletion(role_id, deleted_by) if deleted_by
      end

      success(message: "Role deleted successfully")
    rescue StandardError => e
      failure("Failed to delete role: #{e.message}")
    end

    private

    def log_role_deletion(role_id, deleted_by)
      Rails.logger.info "Role #{role_id} deleted by user #{deleted_by.id}"
    end
  end
end
