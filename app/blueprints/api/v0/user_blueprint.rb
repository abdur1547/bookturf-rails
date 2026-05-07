# frozen_string_literal: true

module Api::V0
  class UserBlueprint < BaseBlueprint
    identifier :id

    fields :full_name, :email, :avatar_url, :created_at, :updated_at, :phone_number

    field :system_role do |user|
      user.system_role
    end
  end
end
