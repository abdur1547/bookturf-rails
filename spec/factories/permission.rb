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

    trait :create_courts do
      resource { "courts" }
      action { "create" }
    end

    trait :update_courts do
      resource { "courts" }
      action { "update" }
    end

    trait :delete_courts do
      resource { "courts" }
      action { "delete" }
    end

    trait :read_pricing do
      resource { "pricing" }
      action { "read" }
    end

    trait :create_pricing do
      resource { "pricing" }
      action { "create" }
    end

    trait :update_pricing do
      resource { "pricing" }
      action { "update" }
    end

    trait :delete_pricing do
      resource { "pricing" }
      action { "delete" }
    end
  end
end
