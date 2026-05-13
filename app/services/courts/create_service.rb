# frozen_string_literal: true

module Courts
  class CreateService < BaseService
    def call(params:, price_per_hour:, pricing_rules: [])
      ApplicationRecord.transaction do
        court = Court.create!(params)
        create_base_rule(court, price_per_hour)
        create_pricing_rules(court, pricing_rules)
        success(court)
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    def create_base_rule(court, price_per_hour)
      PricingRule.create!(
        court_id: court.id,
        venue_id: court.venue_id,
        name: "Regular Price",
        price_per_hour: price_per_hour,
        day_of_week: :all_days,
        priority: 0,
        is_active: true,
        base_rule: true
      )
    end

    def create_pricing_rules(court, pricing_rules_params)
      pricing_rules_params.each do |rule_params|
        PricingRule.create!(
          rule_params.merge(
            court_id: court.id,
            venue_id: court.venue_id,
            priority: rule_params[:priority] || 0
          )
        )
      end
    end
  end
end
