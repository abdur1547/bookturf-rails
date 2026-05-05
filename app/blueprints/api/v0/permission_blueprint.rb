# frozen_string_literal: true

module Api::V0
  class PermissionBlueprint < BaseBlueprint
    identifier :id

    fields :resource, :action

    view :minimal do
      fields :id, :resource, :action
    end
  end
end
