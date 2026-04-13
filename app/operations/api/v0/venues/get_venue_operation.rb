# frozen_string_literal: true

module Api::V0::Venues
  class GetVenueOperation < BaseOperation
    contract do
      params do
        required(:id).filled
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @venue = find_venue(params[:id])
      return Failure(error: "Venue not found") unless @venue

      json_data = serialize

      Success(venue: @venue, json: json_data)
    end

    private

    attr_reader :params, :current_user, :venue

    def find_venue(id)
      # Support both ID and slug
      if id.to_s =~ /\A\d+\z/
        Venue.find_by(id: id)
      else
        Venue.find_by(slug: id)
      end
    end

    def serialize
      Api::V0::VenueBlueprint.render_as_hash(venue, view: :detailed)
    end
  end
end
