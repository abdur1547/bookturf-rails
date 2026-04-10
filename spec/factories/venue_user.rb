# frozen_string_literal: true

FactoryBot.define do
  factory :venue_user do
    association :venue
    association :user
    association :added_by, factory: :user

    joined_at { Time.current }

    trait :recent do
      joined_at { 1.day.ago }
    end

    trait :old do
      joined_at { 6.months.ago }
    end
  end
end
