# frozen_string_literal: true

module Venues
  class VenueUpdaterService < BaseService
    def call(venue:, params:)
      @venue = venue
      @params = params

      if params.key?(:is_active) && venue.is_active != params[:is_active]
        validation_result = Venues::VenueActivationValidatorService.call(
          venue: venue,
          is_active: params[:is_active]
        )
        return validation_result unless validation_result.success?
      end

      if params[:venue_operating_hours].present?
        validation_result = Venues::OperatingHoursValidatorService.call(
          operating_hours: params[:venue_operating_hours]
        )
        return validation_result unless validation_result.success?
      end

      ActiveRecord::Base.transaction do
        return failure(venue.errors.full_messages) unless venue.update(venue_params)

        if params[:venue_setting].present?
          return failure(venue.venue_setting.errors.full_messages) unless venue.venue_setting.update(venue_settings_params)
        end

        if params[:venue_operating_hours].present?
          params[:venue_operating_hours].each do |hour_params|
            day = hour_params[:day_of_week]
            existing_hour = venue.venue_operating_hours.find_by(day_of_week: day)

            if existing_hour
              return failure(existing_hour.errors.full_messages) unless existing_hour.update(hour_params)
            else
              new_hour = venue.venue_operating_hours.build(hour_params)
              return failure(new_hour.errors.full_messages) unless new_hour.save
            end
          end
        end

        success(venue.reload)
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    attr_reader :venue, :params

    def venue_params
      allowed_keys = %i[name description address city state country postal_code
                        latitude longitude phone_number email is_active]
      params.slice(*allowed_keys)
    end

    def venue_settings_params
      allowed_keys = %i[minimum_slot_duration maximum_slot_duration slot_interval
                        advance_booking_days requires_approval cancellation_hours
                        timezone currency]
      params[:venue_setting].slice(*allowed_keys)
    end
  end
end
