# frozen_string_literal: true

module Roles
  class CreateService < BaseService
    def call(params:, created_by: nil)
      role = Role.new(params.merge(is_custom: true))

      ActiveRecord::Base.transaction do
        unless role.save
          return failure(role.errors.full_messages)
        end

        # Assign permissions if provided
        if params[:permission_ids].present?
          assign_permissions(role, params[:permission_ids])
        end

        # Log creation in audit trail
        log_role_creation(role, created_by) if created_by
      end

      success(role)
    rescue StandardError => e
      failure("Failed to create role: #{e.message}")
    end

    private

    def assign_permissions(role, permission_ids)
      permissions = Permission.where(id: permission_ids)
      permissions.each do |permission|
        role.add_permission(permission)
      end
    end

    def log_role_creation(role, created_by)
      Rails.logger.info "Role #{role.id} created by user #{created_by.id}"
    end
  end
end
