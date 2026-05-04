# frozen_string_literal: true

module Api::V0::Courts
  class CreateCourtOperation < BaseOperation
    contract do
      params do
        required(:name).filled(:string)
        required(:venue_id).filled(:integer)
        required(:court_type_id).filled(:integer)
        optional(:description).maybe(:string)
        optional(:slot_interval).maybe(:integer)
        optional(:requires_approval).maybe(:bool)
        optional(:is_active).maybe(:bool)
        required(:pricing_rules).filled(:array) do
          each do
            hash do
              required(:name).filled(:string)
              optional(:day_of_week).maybe(:string, included_in?: PricingRule.day_of_weeks.keys) # "monday", "tuesday",
              # "wednesday", "thursday", "friday", "saturday", "sunday", "all_days", "weekdays", "weekends", default to "all_days"
              optional(:start_date).maybe(:string) # null for all dates
              optional(:start_time).maybe(:string) # null for all times
              optional(:end_date).maybe(:string)   # null for all dates
              optional(:end_time).maybe(:string)   # null for all times
              required(:price_per_hour).filled(:float, gt?: 0) # required, must be > 0
              optional(:priority).maybe(:integer)
              optional(:is_active).maybe(:bool)
            end
          end
        end
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @venue = Venue.find_by(id: params[:venue_id])
      return Failure("Venue not found") unless @venue
      @court_type = CourtType.find_by(id: params[:court_type_id])
      return Failure("Court type not found") unless @court_type
      return Failure(:forbidden) unless authorize?

      court_params = params.slice(
        :venue_id,
        :name,
        :description,
        :slot_interval,
        :requires_approval,
        :is_active,
        :court_type_id
      ).compact

      result = Courts::CreateService.call(params: court_params, pricing_rules: params[:pricing_rules])
      return Failure(result.error) unless result.success?

      @court = result.data
      json_data = serialize
      Success(court: @court, json: json_data)
    end

    private

    attr_reader :params, :current_user, :court, :venue, :court_type

    def authorize?
      VenuePolicy.new(current_user, venue).update?
    end

    def serialize
      Api::V0::CourtBlueprint.render_as_hash(court, view: :detailed)
    end
  end
end
