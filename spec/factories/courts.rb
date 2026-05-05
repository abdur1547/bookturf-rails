# frozen_string_literal: true

FactoryBot.define do
  factory :court do
    association :venue
    association :court_type

    sequence(:name) { |n| "Court #{n}" }
    description { "Premium indoor court" }
    is_active { true }
  end
end
