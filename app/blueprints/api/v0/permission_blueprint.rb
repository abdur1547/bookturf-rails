# frozen_string_literal: true

module Api::V0
  class PermissionBlueprint < BaseBlueprint
    identifier :id

    fields :name, :resource, :action, :description

    view :minimal do
      fields :id, :name
    end
  end
end
