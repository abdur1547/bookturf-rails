# frozen_string_literal: true

module Roles
  class UpdateService < BaseService
    def call(role:, params:, updated_by: nil)
      ActiveRecord::Base.transaction do
        update_params = params.except(:permission_ids)
        unless role.update(update_params)
          return failure(role.errors.full_messages)
        end

        if params[:permission_ids]
          sync_result = Roles::SyncPermissionsService.call(
            role: role,
            permission_ids: params[:permission_ids]
          )
          return sync_result unless sync_result.success?
        end

        log_role_update(role, updated_by) if updated_by
      end

      success(role)
    rescue StandardError => e
      failure("Failed to update role: #{e.message}")
    end

    private

    def log_role_update(role, updated_by)
      Rails.logger.info "Role #{role.id} updated by user #{updated_by.id}"
    end
  end
end
