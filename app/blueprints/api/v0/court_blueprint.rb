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
           :display_order,
           :created_at,
           :updated_at

    view :list do
      fields :slot_interval,
             :requires_approval

      field :sport_type_name do |court|
        court.sport_type_name
      end

      field :venue_name do |court|
        court.venue_name
      end

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

      association :court_type, blueprint: Api::V0::CourtTypeBlueprint, view: :minimal
      association :venue, blueprint: Api::V0::VenueBlueprint, view: :minimal do |court|
        court.venue
      end
    end

    view :detailed do
      fields :slot_interval,
             :requires_approval

      field :sport_type_name do |court|
        court.sport_type_name
      end

      field :venue_name do |court|
        court.venue_name
      end

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
            url: image["url"],
            alt_text: image["alt_text"],
            display_order: image["display_order"]
          }
        end
      end

      association :court_type, blueprint: Api::V0::CourtTypeBlueprint, view: :minimal
      association :venue, blueprint: Api::V0::VenueBlueprint, view: :minimal do |court|
        court.venue
      end

      association :pricing_rules, blueprint: Api::V0::PricingRuleBlueprint, view: :list do |court|
        court.pricing_rules
      end
    end

    view :minimal do
      fields :id,
             :name,
             :is_active,
             :court_type_id,
             :venue_id
    end
  end
end
