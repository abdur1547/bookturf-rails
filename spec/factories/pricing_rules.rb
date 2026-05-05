# frozen_string_literal: true

FactoryBot.define do
  factory :pricing_rule do
    association :venue
    association :court
    sequence(:name) { |n| "Pricing Rule #{n}" }
    price_per_hour { 2500.0 }
    day_of_week { nil }
    start_time { '18:00' }
    end_time { '23:00' }
    start_date { nil }
    end_date { nil }
    priority { 1 }
    is_active { true }
  end
end
