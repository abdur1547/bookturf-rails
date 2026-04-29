# frozen_string_literal: true

module Venues
  class VenueUpdaterService < BaseService
    def call(venue:, params:)
      @venue = venue
      @params = params

      result = validate_activation_change
      return result if result && !result.success?

      result = validate_operating_hours
      return result if result && !result.success?

      persist_changes
      success(venue.reload)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    attr_reader :venue, :params

    def validate_activation_change
      return unless params.key?(:is_active) && venue.is_active != params[:is_active]

      Venues::VenueActivationValidatorService.call(venue: venue, is_active: params[:is_active])
    end

    def validate_operating_hours
      return unless params[:venue_operating_hours].present?

      Venues::OperatingHoursValidatorService.call(
        operating_hours: params[:venue_operating_hours],
        is_update: true
      )
    end

    def persist_changes
      ActiveRecord::Base.transaction do
        update_venue
        update_operating_hours
      end
    end

    def update_venue
      venue.update!(venue_params) if venue_params.present?
    end

    def update_operating_hours
      return unless params[:venue_operating_hours].present?

      params[:venue_operating_hours].each do |hours|
        existing = venue.venue_operating_hours.find_by(day_of_week: hours[:day_of_week])
        existing.update!(hours) if existing
      end
    end

    def venue_params
      allowed_keys = %i[name description address city state country postal_code
                        latitude longitude phone_number email timezone currency is_active]
      params.compact&.slice(*allowed_keys)
    end
  end
end
