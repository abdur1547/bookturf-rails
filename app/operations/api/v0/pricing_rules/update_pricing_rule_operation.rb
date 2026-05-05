# frozen_string_literal: true

module Api::V0::PricingRules
  class UpdatePricingRuleOperation < BaseOperation
    contract do
      params do
        required(:id).filled
        optional(:name).maybe(:string)
        optional(:price_per_hour).filled(:float, gt?: 0)
        optional(:day_of_week).maybe(:string, included_in?: PricingRule.day_of_weeks.keys)
        optional(:start_time).maybe(:string)
        optional(:end_time).maybe(:string)
        optional(:start_date).maybe(:string)
        optional(:end_date).maybe(:string)
        optional(:priority).maybe(:integer)
        optional(:is_active).maybe(:bool)
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @pricing_rule = PricingRule.find_by(id: params[:id])
      return Failure(:not_found) unless @pricing_rule

      @venue = @pricing_rule.venue
      return Failure(:forbidden) unless VenuePolicy.new(current_user, @venue).update?

      update_params = params.slice(:name, :price_per_hour, :day_of_week,
                                   :start_time, :end_time, :start_date, :end_date,
                                   :priority, :is_active)
      result = PricingRules::UpdateService.call(pricing_rule: @pricing_rule, params: update_params)
      return Failure(result.error) unless result.success?

      @pricing_rule = result.data
      json_data = serialize
      Success(pricing_rule: @pricing_rule, json: json_data)
    end

    private

    attr_reader :params, :current_user, :pricing_rule, :venue

    def serialize
      Api::V0::PricingRuleBlueprint.render_as_hash(pricing_rule)
    end
  end
end
