# frozen_string_literal: true

module PricingRules
  class CreateService < BaseService
    def call(params:)
      pricing_rule = PricingRule.create!(pricing_rule_params(params))
      success(pricing_rule)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end

    private

    def pricing_rule_params(params)
      params.slice(:name, :venue_id, :court_id, :day_of_week, :start_date, :start_time, :end_date, :end_time,
      :price_per_hour, :priority, :is_active)
    end
  end
end
