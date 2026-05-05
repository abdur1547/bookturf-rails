# frozen_string_literal: true

module Api::V0
  class UserBlueprint < BaseBlueprint
    identifier :id

    fields :full_name, :email, :avatar_url, :created_at, :updated_at, :phone_number

    field :system_role do |user|
      user.system_role
    end

    field :preferences do |user|
      {
        preferred_city: nil,
        preferred_town: nil,
        notification_reminders: true,
        notification_30min: true
      }
    end

    field :owned_venue_id do |user|
      user.owned_venues.first&.id
    end

    view :minimal do
      fields :id, :full_name
    end
  end
end
