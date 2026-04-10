# frozen_string_literal: true

FactoryBot.define do
  factory :venue_operating_hour do
    association :venue

    day_of_week { 1 } # Monday
    opens_at { "09:00" }
    closes_at { "23:00" }
    is_closed { false }

    trait :closed do
      is_closed { true }
    end

    trait :weekend do
      day_of_week { 0 } # Sunday
      opens_at { "08:00" }
      closes_at { "00:00" } # Midnight
    end

    trait :monday do
      day_of_week { 1 }
    end

    trait :tuesday do
      day_of_week { 2 }
    end

    trait :wednesday do
      day_of_week { 3 }
    end

    trait :thursday do
      day_of_week { 4 }
    end

    trait :friday do
      day_of_week { 5 }
    end

    trait :saturday do
      day_of_week { 6 }
    end

    trait :sunday do
      day_of_week { 0 }
    end
  end
end
