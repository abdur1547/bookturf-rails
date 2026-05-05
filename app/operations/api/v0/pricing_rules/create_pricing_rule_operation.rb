# frozen_string_literal: true

module Api::V0::PricingRules
  class CreatePricingRuleOperation < BaseOperation
    contract do
      params do
        required(:name).filled(:string)
        required(:court_id).filled(:integer)
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

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @court = Court.find_by(id: params[:court_id])
      return Failure(:not_found) unless @court
      @venue = @court.venue
      return Failure(:forbidden) unless VenuePolicy.new(current_user, @venue).update?

      create_params = params.merge(court_id: @court.id, venue_id: @venue.id)
      result = PricingRules::CreateService.call(params: create_params)
      return Failure(result.error) unless result.success?

      @pricing_rule = result.data
      json_data = serialize
      Success(pricing_rule: @pricing_rule, json: json_data)
    end

    private

    attr_reader :params, :current_user, :pricing_rule, :court, :venue

    def serialize
      Api::V0::PricingRuleBlueprint.render_as_hash(pricing_rule)
    end
  end
end
