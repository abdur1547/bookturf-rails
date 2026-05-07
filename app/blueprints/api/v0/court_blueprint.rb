# frozen_string_literal: true

module Api::V0
  class CourtBlueprint < BaseBlueprint
    identifier :id

    fields :name,
           :description,
           :court_type_id,
           :venue_id,
           :slot_interval,
           :requires_approval,
           :is_active,
           :court_type_name,
           :venue_name

    field :city do |court|
      court.venue&.city
    end

    field :price_range do |court|
      range = court.price_range
      {
        min: range[:min],
        max: range[:max]
      }
    end

    field :images do |court|
      court.images_array.map do |image|
        {
          id: image["id"],
          url: image["url"]
        }
      end
    end

    association :pricing_rules, blueprint: Api::V0::PricingRuleBlueprint
  end
end
