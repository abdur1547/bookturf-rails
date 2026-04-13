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
           :is_active,
           :created_at

    # List view - for public index endpoint
    view :list do
      fields :id,
             :name,
             :slug,
             :description,
             :address,
             :city,
             :state,
             :country,
             :postal_code,
             :phone_number,
             :email,
             :latitude,
             :longitude,
             :is_active,
             :created_at

      field :google_maps_url do |venue|
        venue.google_maps_url
      end

      field :courts_count do |venue|
        venue.courts.count
      end
    end

    # Detailed view - for show, create, update endpoints
    view :detailed do
      fields :id,
             :name,
             :slug,
             :description,
             :address,
             :city,
             :state,
             :country,
             :postal_code,
             :phone_number,
             :email,
             :latitude,
             :longitude,
             :is_active,
             :created_at,
             :updated_at

      field :google_maps_url do |venue|
        venue.google_maps_url
      end

      association :owner, blueprint: Api::V0::UserBlueprint, view: :minimal do |venue|
        venue.owner
      end

      association :venue_setting, blueprint: Api::V0::VenueSettingBlueprint do |venue|
        venue.venue_setting
      end

      association :venue_operating_hours, blueprint: Api::V0::VenueOperatingHourBlueprint do |venue|
        venue.venue_operating_hours.order(:day_of_week)
      end

      field :courts_count do |venue|
        venue.courts.count
      end
    end

    # Minimal view - for nested associations
    view :minimal do
      fields :id, :name, :slug, :city
    end
  end
end
