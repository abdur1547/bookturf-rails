# frozen_string_literal: true

module Api::V0::Venues
  class ListAvailabilityOperation < BaseOperation
    contract do
      params do
        required(:id).filled(:string)
        required(:start_date).filled(:string)
        optional(:end_date).maybe(:string)
        optional(:duration_minutes).maybe(:integer)
        optional(:court_type_id).maybe(:integer)
        optional(:court_id).maybe(:integer)
        optional(:include_booked).maybe(:bool)
      end
    end

    def call(params)
      @params = params
      venue = find_venue
      return Failure(error: "Venue not found") unless venue

      start_date = parse_date(params[:start_date])
      return Failure(error: "Invalid start_date") unless start_date

      end_date = parse_date(params[:end_date] || params[:start_date])
      return Failure(error: "Invalid end_date") unless end_date

      return Failure(error: "end_date must be on or after start_date") if end_date < start_date

      settings = venue.venue_setting
      return Failure(error: "Venue settings are required") unless settings

      duration_minutes = parse_duration(params[:duration_minutes], settings.minimum_slot_duration)
      return Failure(error: "Invalid duration_minutes") unless duration_minutes

      unless valid_duration?(duration_minutes, settings)
        return Failure(error: "duration_minutes must be between #{settings.minimum_slot_duration} and #{settings.maximum_slot_duration} and a multiple of #{settings.slot_interval}")
      end

      availability = Venues::AvailabilityService.call(
        venue: venue,
        start_date: start_date,
        end_date: end_date,
        duration_minutes: duration_minutes,
        court_type_id: parse_integer(params[:court_type_id]),
        court_id: parse_integer(params[:court_id]),
        include_booked: parse_boolean(params[:include_booked])
      )

      return Failure(error: availability.error) unless availability.success?

      Success(json: availability.data)
    end

    private

    attr_reader :params

    def find_venue
      Venue.find_by(id: params[:id]) || Venue.find_by(slug: params[:id])
    end

    def parse_date(value)
      Date.iso8601(value)
    rescue ArgumentError, TypeError
      nil
    end

    def parse_duration(value, default_duration)
      return default_duration if value.nil? || value.to_s.strip.empty?
      Integer(value)
    rescue ArgumentError, TypeError
      nil
    end

    def valid_duration?(duration, settings)
      duration >= settings.minimum_slot_duration &&
        duration <= settings.maximum_slot_duration &&
        (duration % settings.slot_interval).zero?
    end

    def parse_integer(value)
      return nil if value.nil? || value.to_s.strip.empty?
      Integer(value)
    rescue ArgumentError, TypeError
      nil
    end

    def parse_boolean(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end
  end
end
