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
      return Failure(:not_found) unless venue

      start_date = parse_date(params[:start_date])
      return Failure("Invalid start_date") unless start_date

      end_date = parse_date(params[:end_date] || params[:start_date])
      return Failure("Invalid end_date") unless end_date

      return Failure("end_date must be on or after start_date") if end_date < start_date

      availability = Venues::AvailabilityService.call(
        venue: venue,
        start_date: start_date,
        end_date: end_date,
        duration_minutes: parse_integer(params[:duration_minutes]),
        court_type_id: parse_integer(params[:court_type_id]),
        court_id: parse_integer(params[:court_id]),
        include_booked: parse_boolean(params[:include_booked])
      )

      return Failure(availability.error) unless availability.success?

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
