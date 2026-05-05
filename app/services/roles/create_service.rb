# frozen_string_literal: true

module Roles
  class CreateService < BaseService
    def call(params:, created_by: nil)
      role = Role.new(params)

      ActiveRecord::Base.transaction do
        unless role.save
          return failure(role.errors.full_messages)
        end

        log_role_creation(role, created_by) if created_by
      end

      success(role)
    rescue StandardError => e
      failure("Failed to create role: #{e.message}")
    end

    private

    def log_role_creation(role, created_by)
      Rails.logger.info "Role #{role.id} created by user #{created_by.id}"
    end
  end
end
