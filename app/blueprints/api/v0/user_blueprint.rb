# frozen_string_literal: true

module Api::V0
  class UserBlueprint < BaseBlueprint
    identifier :id

    fields :email, :name

    view :profile do
      fields :name, :email, :avatar_url, :created_at
      field :member_since do |user|
        "Member since #{user.created_at&.strftime('%B %Y')}"
      end
    end

    view :minimal do
      fields :id, :name
    end
  end
end
