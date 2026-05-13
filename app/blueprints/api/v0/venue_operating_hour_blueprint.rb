# frozen_string_literal: true

module Api::V0
  class VenueOperatingHourBlueprint < BaseBlueprint
    identifier :id

    fields :day_of_week, :is_closed, :is_open_24h, :venue_id

    field :opens_at do |hour|
      hour.opens_at.strftime(Constants::API_TIME_FORMAT) if hour.opens_at.present?
    end

    field :closes_at do |hour|
      hour.closes_at.strftime(Constants::API_TIME_FORMAT) if hour.closes_at.present?
    end

    field :day_name do |hour|
      hour.day_name
    end

    field :formatted_hours do |hour|
      hour.formatted_hours
    end
  end
end
