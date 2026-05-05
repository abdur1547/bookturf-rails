# frozen_string_literal: true

FactoryBot.define do
  factory :permission do
    resource { "bookings" }
    action { "read" }

    trait :create_bookings do
      resource { "bookings" }
      action { "create" }
    end

    trait :read_bookings do
      resource { "bookings" }
      action { "read" }
    end

    trait :manage_bookings do
      resource { "bookings" }
      action { "manage" }
    end

    trait :read_courts do
      resource { "courts" }
      action { "read" }
    end
  end
end
