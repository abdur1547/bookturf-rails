# frozen_string_literal: true

module Api::V0::Venues
  class DeleteVenueOperation < BaseOperation
    contract do
      params do
        required(:id).filled
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @venue = current_user.owned_and_member_venues.find_by(id: params[:id])
      return Failure(:not_found) unless venue

      return Failure(:forbidden) unless authorize?

      result = Venues::VenueDestroyerService.call(venue: venue)

      return Failure(result.error) unless result.success?

      json_data = serialize

      Success(venue: venue, json: json_data)
    end

    private

    attr_reader :params, :current_user, :venue

    def authorize?
      VenuePolicy.new(current_user, venue).destroy?
    end

    def serialize
      { message: "Venue deleted successfully" }
    end
  end
end
