# frozen_string_literal: true

module Api::V0::Venues
  class CreateVenueOperation < BaseOperation
    contract_class Api::V0::Contracts::Venues::VenueContract

    def call(params, current_user)
      @params = params
      @current_user = current_user

      return Failure(:forbidden) unless authorize?

      result = Venues::VenueCreatorService.call(
        params: params,
        owner: current_user
      )

      return Failure(result.error) unless result.success?

      @venue = result.data
      json_data = serialize

      Success(venue: @venue, json: json_data)
    end

    private

    attr_reader :params, :current_user, :venue

    def authorize?
      VenuePolicy.new(current_user, Venue).create?
    end

    def serialize
      Api::V0::VenueBlueprint.render_as_hash(venue)
    end
  end
end
