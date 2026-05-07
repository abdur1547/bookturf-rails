# frozen_string_literal: true

module Api::V0
  class RoleBlueprint < BaseBlueprint
    identifier :id

    fields :name, :venue_id, :created_at, :updated_at

    association :permissions, blueprint: Api::V0::PermissionBlueprint
  end
end
