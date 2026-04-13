# frozen_string_literal: true

module Api::V0::Venues
  class UpdateVenueOperation < BaseOperation
    contract do
      params do
        required(:id).filled
        required(:venue).hash do
          optional(:name).maybe(:string)
          optional(:description).maybe(:string)
          optional(:address).maybe(:string)
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

      @venue = find_venue(params[:id])
      return Failure(error: "Venue not found") unless @venue

      return Failure(:unauthorized) unless authorize

      result = Venues::VenueUpdaterService.call(
        venue: @venue,
        params: venue_params
      )

      return Failure(errors: result.error) unless result.success?

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
