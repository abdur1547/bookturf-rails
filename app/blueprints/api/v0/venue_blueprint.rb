# frozen_string_literal: true

module Api::V0
  class VenueBlueprint < BaseBlueprint
    identifier :id

    fields :name,
           :slug,
           :description,
           :address,
           :city,
           :state,
           :country,
           :postal_code,
           :phone_number,
           :email,
           :timezone,
           :currency,
           :is_active,
           :created_at

    field :latitude do |venue|
        venue.latitude&.to_f
      end

    field :longitude do |venue|
      venue.longitude&.to_f
    end

    field :google_maps_url do |venue|
      venue.google_maps_url
    end

    field :courts_count do |venue|
      venue.courts.count
    end

    association :venue_operating_hours, blueprint: Api::V0::VenueOperatingHourBlueprint do |venue|
      venue.venue_operating_hours.order(:day_of_week)
    end
  end
end
