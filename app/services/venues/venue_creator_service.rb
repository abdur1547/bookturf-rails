# frozen_string_literal: true

module Venues
  class VenueCreatorService < BaseService
    def call(params:, owner:)
      @params = params
      @owner = owner

      if params[:venue_operating_hours].present?
        validation_result = Venues::OperatingHoursValidatorService.call(
          operating_hours: params[:venue_operating_hours]
        )
        return validation_result unless validation_result.success?
      end

      ActiveRecord::Base.transaction do
        venue = Venue.create!(venue_params)
        venue.venue_operating_hours.create!(venue_hours_params)

        return success(venue.reload)
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    attr_reader :params, :owner

    def venue_params
      {
        name: params[:name],
        description: params[:description],
        address: params[:address],
        city: params[:city],
        state: params[:state],
        country: params[:country],
        postal_code: params[:postal_code],
        latitude: params[:latitude],
        longitude: params[:longitude],
        phone_number: params[:phone_number],
        email: params[:email],
        timezone: params[:timezone] || "Asia/Karachi",
        currency: params[:currency] || "PKR",
        is_active: params.fetch(:is_active, true),
        owner_id: owner.id
      }.compact
    end

    def venue_hours_params
      return default_operating_hours unless params[:venue_operating_hours].present?
      params[:venue_operating_hours]
    end

    def default_operating_hours
      (0..6).map do |day|
        {
          day_of_week: day,
          opens_at: "09:00",
          closes_at: "23:00",
          is_closed: false
        }
      end
    end
  end
end
