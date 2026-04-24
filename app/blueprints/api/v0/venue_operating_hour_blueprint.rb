# frozen_string_literal: true

module Api::V0
  class VenueOperatingHourBlueprint < BaseBlueprint
    identifier :id

    fields :day_of_week, :opens_at, :closes_at, :is_closed, :venue_id

    field :day_name do |hour|
      hour.day_name
    end

    field :formatted_hours do |hour|
      hour.formatted_hours
    end
  end
end
