# frozen_string_literal: true

module Api::V0
  class RoleBlueprint < BaseBlueprint
    identifier :id

    fields :name, :venue_id, :created_at

    view :list do
      fields :id, :name, :venue_id, :created_at

      field :permissions_count do |role|
        role.permissions.count
      end

      field :members_count do |role|
        role.venue_memberships.count
      end
    end

    view :detailed do
      fields :id, :name, :venue_id, :created_at, :updated_at

      association :permissions, blueprint: Api::V0::PermissionBlueprint do |role|
        role.permissions
      end
    end

    view :minimal do
      fields :id, :name
    end
  end
end
