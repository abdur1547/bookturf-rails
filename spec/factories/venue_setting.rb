# frozen_string_literal: true

FactoryBot.define do
  factory :venue_setting do
    association :venue

    minimum_slot_duration { 60 }
    maximum_slot_duration { 180 }
    slot_interval { 30 }
    advance_booking_days { 30 }
    requires_approval { false }
    cancellation_hours { 24 }
    timezone { "Asia/Karachi" }
    currency { "PKR" }

    trait :short_slots do
      minimum_slot_duration { 30 }
      maximum_slot_duration { 60 }
      slot_interval { 15 }
    end

    trait :requires_approval do
      requires_approval { true }
    end
  end
end
