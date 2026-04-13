# frozen_string_literal: true

module Venues
  class VenueCreatorService < BaseService
    def call(params:, owner:)
      venue_params = params.except(:venue_setting, :venue_operating_hours)
      setting_params = params[:venue_setting]
      hours_params = params[:venue_operating_hours]

      venue_params[:owner_id] = owner.id

      if hours_params.present?
        validation_result = Venues::OperatingHoursValidatorService.call(
          operating_hours: hours_params
        )
        return validation_result unless validation_result.success?
      end

      ActiveRecord::Base.transaction do
        venue = Venue.new(venue_params)

        unless venue.save
          return failure(venue.errors.full_messages)
        end

        update_settings(venue, setting_params)
        update_operating_hours(venue, hours_params)

        venue.reload
        success(venue)
      end
    rescue StandardError => e
      failure("Failed to create venue: #{e.message}")
    end
  end

  private

  def update_settings(venue, setting_params)
    if setting_params.present?
      unless venue.venue_setting.update(setting_params)
        failure(venue.venue_setting.errors.full_messages)
      end
    end
  end

  def update_operating_hours(venue, hours_params)
    if hours_params.present?
      hours_params.each do |hour_params|
        day = hour_params[:day_of_week]
        existing_hour = venue.venue_operating_hours.find_by(day_of_week: day)

        if existing_hour
          unless existing_hour.update(hour_params)
            failure(existing_hour.errors.full_messages)
          end
        end
      end
    end
  end
end
