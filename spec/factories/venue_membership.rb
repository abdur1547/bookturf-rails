# frozen_string_literal: true

FactoryBot.define do
  factory :venue_membership do
    association :user
    association :venue
    association :role
  end
end
