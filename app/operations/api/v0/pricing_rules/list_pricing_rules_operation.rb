# frozen_string_literal: true

module Api::V0::PricingRules
  class ListPricingRulesOperation < BaseOperation
    contract do
      # TODO: add filter by name
      params do
        required(:court_id).filled(:integer)
        optional(:is_active).maybe(:bool)
        optional(:day_of_week).maybe(:string, included_in?: PricingRule.day_of_weeks.keys)
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @court = Court.find_by(id: params[:court_id])
      return Failure(:not_found) unless @court

      # Reuse PricingRule instance for policy check with venue context
      sample_rule = PricingRule.new(venue: @court.venue)
      return Failure(:forbidden) unless PricingRulePolicy.new(current_user, sample_rule).index?

      @pricing_rules = PricingRule.where(court: @court)

      if params.key?(:is_active)
        if params[:is_active] == true || params[:is_active] == "true"
          @pricing_rules = @pricing_rules.active
        elsif params[:is_active] == false || params[:is_active] == "false"
          @pricing_rules = @pricing_rules.where(is_active: false)
        end
      end

      if params[:day_of_week].present?
        day_value = PricingRule.day_of_weeks[params[:day_of_week]]
        @pricing_rules = @pricing_rules.where(day_of_week: day_value)
      end

      @pricing_rules = @pricing_rules.order(priority: :desc, name: :asc)
      json_data = serialize

      Success(pricing_rules: @pricing_rules, json: json_data)
    end

    private

    attr_reader :params, :current_user, :pricing_rules

    def serialize
      Api::V0::PricingRuleBlueprint.render_as_hash(@pricing_rules, view: :list)
    end
  end
end
