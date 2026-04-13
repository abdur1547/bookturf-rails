# frozen_string_literal: true

module Venues
  class VenueUpdaterService < BaseService
    def call(venue:, params:)
      venue_params = params.except(:venue_setting, :venue_operating_hours, :owner_id, :slug, :created_at)
      setting_params = params[:venue_setting]
      hours_params = params[:venue_operating_hours]
      validate_activation(venue, venue_params[:is_active])
      validate_operating_hours(hours_params)

      ActiveRecord::Base.transaction do
        unless venue.update(venue_params)
          return failure(venue.errors.full_messages)
        end

        # Update settings if provided
        if setting_params.present?
          unless venue.venue_setting.update(setting_params)
            return failure(venue.venue_setting.errors.full_messages)
          end
        end

        # Update operating hours if provided
        if hours_params.present?
          hours_params.each do |hour_params|
            day = hour_params[:day_of_week]
            existing_hour = venue.venue_operating_hours.find_by(day_of_week: day)

            if existing_hour
              unless existing_hour.update(hour_params)
                return failure(existing_hour.errors.full_messages)
              end
            else
              # Create new operating hour if it doesn't exist
              new_hour = venue.venue_operating_hours.build(hour_params)
              unless new_hour.save
                return failure(new_hour.errors.full_messages)
              end
            end
          end
        end

        venue.reload
        success(venue)
      end
    rescue StandardError => e
      failure("Failed to update venue: #{e.message}")
    end
  end

  private

  def validate_activation(venue, is_active)
    if venue_params.key?(:is_active) && venue.is_active != venue_params[:is_active]
      validation_result = Venues::VenueActivationValidatorService.call(
        venue: venue,
        is_active: venue_params[:is_active]
      )
      validation_result unless validation_result.success?
    end
  end

  def validate_operating_hours(operating_hours)
    if operating_hours.present?
      validation_result = Venues::OperatingHoursValidatorService.call(
        operating_hours: operating_hours
      )
      validation_result unless validation_result.success?
    end
  end
end
