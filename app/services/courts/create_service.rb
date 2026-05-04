# frozen_string_literal: true

module Courts
  class CreateService < BaseService
    def call(params:, pricing_rules: [])
      ApplicationRecord.transaction do
        court = Court.create!(params)
        create_pricing_rules(court, pricing_rules)
        success(court)
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

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
