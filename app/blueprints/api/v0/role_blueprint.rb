# frozen_string_literal: true

module Api::V0
  class RoleBlueprint < BaseBlueprint
    identifier :id

    fields :name, :slug, :description, :is_custom, :created_at

    # List view - for index endpoint
    view :list do
      fields :id, :name, :slug, :description, :is_custom, :created_at

      field :permissions_count do |role|
        role.permissions.count
      end

      field :users_count do |role|
        role.users.count
      end
    end

    # Detailed view - for show endpoint
    view :detailed do
      fields :id, :name, :slug, :description, :is_custom, :created_at, :updated_at

      association :permissions, blueprint: Api::V0::PermissionBlueprint do |role|
        role.permissions
      end

      association :users, blueprint: Api::V0::UserBlueprint, view: :minimal do |role|
        role.users
      end
    end

    # Minimal view - for nested associations
    view :minimal do
      fields :id, :name, :slug
    end
  end
end
