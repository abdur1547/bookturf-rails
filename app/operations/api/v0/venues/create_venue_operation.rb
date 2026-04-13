# frozen_string_literal: true

module Api::V0::Venues
  class CreateVenueOperation < BaseOperation
    contract do
      params do
        required(:venue).hash do
          required(:name).filled(:string)
          optional(:description).maybe(:string)
          required(:address).filled(:string)
          optional(:city).maybe(:string)
          optional(:state).maybe(:string)
          optional(:country).maybe(:string)
          optional(:postal_code).maybe(:string)
          optional(:latitude).maybe(:decimal)
          optional(:longitude).maybe(:decimal)
          optional(:phone_number).maybe(:string)
          optional(:email).maybe(:string)
          optional(:is_active).maybe(:bool)

          optional(:venue_setting).maybe(:hash) do
            optional(:minimum_slot_duration).maybe(:integer)
            optional(:maximum_slot_duration).maybe(:integer)
            optional(:slot_interval).maybe(:integer)
            optional(:advance_booking_days).maybe(:integer)
            optional(:requires_approval).maybe(:bool)
            optional(:cancellation_hours).maybe(:integer)
            optional(:timezone).maybe(:string)
            optional(:currency).maybe(:string)
          end

          optional(:venue_operating_hours).maybe(:array) do
            hash do
              required(:day_of_week).filled(:integer)
              optional(:opens_at).maybe(:string)
              optional(:closes_at).maybe(:string)
              optional(:is_closed).maybe(:bool)
            end
          end
        end
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user
      venue_params = params[:venue]

      return Failure(:unauthorized) unless authorize

      result = Venues::VenueCreatorService.call(
        params: venue_params,
        owner: current_user
      )

      return Failure(errors: result.error) unless result.success?

      @venue = result.data
      json_data = serialize

      Success(venue: @venue, json: json_data)
    end

    private

    attr_reader :params, :current_user, :venue

    def authorize
      VenuePolicy.new(current_user, Venue).create?
    end

    def serialize
      Api::V0::VenueBlueprint.render_as_hash(venue, view: :detailed)
    end
  end
end
