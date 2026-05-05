# frozen_string_literal: true

module Roles
  class DeleteService < BaseService
    def call(role:, deleted_by: nil)
      return failure("Cannot delete role with active memberships") if role.venue_memberships.any?

      ActiveRecord::Base.transaction do
        role_id = role.id
        role.destroy!

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
