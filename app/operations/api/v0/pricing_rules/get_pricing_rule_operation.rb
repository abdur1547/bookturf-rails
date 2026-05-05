# frozen_string_literal: true

module Api::V0::PricingRules
  class GetPricingRuleOperation < BaseOperation
    contract do
      params do
        required(:id).filled
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @pricing_rule = PricingRule.find_by(id: params[:id])
      return Failure(:not_found) unless @pricing_rule

      return Failure(:forbidden) unless authorized?

      json_data = serialize
      Success(pricing_rule: @pricing_rule, json: json_data)
    end

    private

    attr_reader :params, :current_user, :pricing_rule

    def authorized?
      PricingRulePolicy.new(current_user, @pricing_rule).show?
    end

    def serialize
      Api::V0::PricingRuleBlueprint.render_as_hash(pricing_rule)
    end
  end
end
