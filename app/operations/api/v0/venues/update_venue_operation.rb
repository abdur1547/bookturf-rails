# frozen_string_literal: true

module Api::V0::Venues
  class UpdateVenueOperation < BaseOperation
    contract_class Api::V0::Contracts::Venues::UpdateVenueContract

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @venue = Venue.find_by(id: params[:id])
      return Failure(:not_found) unless @venue

      return Failure(:forbidden) unless authorize

      result = Venues::VenueUpdaterService.call(
        venue: @venue,
        params: params
      )

      return Failure(result.error) unless result.success?

      @venue = result.data
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

    def authorize
      VenuePolicy.new(current_user, venue).update?
    end

    def serialize
      Api::V0::VenueBlueprint.render_as_hash(venue, view: :detailed)
    end
  end
end
