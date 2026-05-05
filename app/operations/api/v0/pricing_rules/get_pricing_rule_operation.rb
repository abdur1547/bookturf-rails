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

      return Failure(:forbidden) unless authorized_role?

      @pricing_rule = PricingRule.find_by(id: params[:id])
      return Failure(:not_found) unless @pricing_rule
      return Failure(:forbidden) unless pricing_rule_accessible?

      json_data = serialize
      Success(pricing_rule: @pricing_rule, json: json_data)
    end

    private

    attr_reader :params, :current_user, :pricing_rule

    def authorized_role?
      PricingRulePolicy.new(current_user, PricingRule).show?
    end

    # TODO: move this check to a policy class
    def pricing_rule_accessible?
      current_user.admin? || accessible_venue_ids.include?(@pricing_rule.venue_id)
    end

    def accessible_venue_ids
      (current_user.venues.pluck(:id) + current_user.owned_venues.pluck(:id)).uniq
    end

    def serialize
      Api::V0::PricingRuleBlueprint.render_as_hash(pricing_rule)
    end
  end
end
