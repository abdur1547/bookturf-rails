# frozen_string_literal: true

module Api::V0::Courts
  class CreateCourtOperation < BaseOperation
    contract do
      params do
        required(:venue_id).filled(:integer)
        required(:court_type_id).filled(:integer)
        required(:name).filled(:string)
        optional(:description).maybe(:string)
        optional(:slot_interval).maybe(:integer)
        optional(:requires_approval).maybe(:bool)
        optional(:is_active).maybe(:bool)
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @venue = Venue.find_by(id: params[:venue_id])
      return Failure(:not_found) unless @venue
      @court_type = CourtType.find_by(id: params[:court_type_id])
      return Failure(:not_found) unless court_type
      return Failure(:forbidden) unless authorize?

      court_params = params.slice(
        :venue_id,
        :name,
        :description,
        :slot_interval,
        :requires_approval,
        :is_active,
        :court_type_id
      ).compact

      result = Courts::CreateService.call(params: court_params)
      return Failure(result.error) unless result.success?

      @court = result.data
      json_data = serialize
      Success(court: @court, json: json_data)
    end

    private

    attr_reader :params, :current_user, :court, :venue, :court_type

    def authorize?
      VenuePolicy.new(current_user, venue).update?
    end

    def serialize
      Api::V0::CourtBlueprint.render_as_hash(court, view: :detailed)
    end
  end
end
