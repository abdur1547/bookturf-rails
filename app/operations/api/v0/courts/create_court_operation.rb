# frozen_string_literal: true

module Api::V0::Courts
  class CreateCourtOperation < BaseOperation
    contract do
      params do
        required(:court).hash do
          required(:venue_id).filled(:integer)
          optional(:sport_type_id).maybe(:integer)
          optional(:court_type_id).maybe(:integer)
          optional(:sport_type_name).maybe(:string)
          required(:name).filled(:string)
          optional(:description).maybe(:string)
          optional(:slot_interval).maybe(:integer)
          optional(:requires_approval).maybe(:bool)
          optional(:is_active).maybe(:bool)
          optional(:display_order).maybe(:integer)
        end
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user
      raw_court_params = params[:court]

      @venue = Venue.find_by(id: raw_court_params[:venue_id])
      return Failure(:not_found) unless @venue
      return Failure(:forbidden) unless authorize

      court_type_id = raw_court_params[:sport_type_id].presence || raw_court_params[:court_type_id].presence
      if court_type_id.blank? && raw_court_params[:sport_type_name].present?
        court_type_id = find_court_type_id(raw_court_params[:sport_type_name])
        return Failure(:not_found) unless court_type_id
      end

      court_params = raw_court_params.slice(
        :venue_id,
        :name,
        :description,
        :slot_interval,
        :requires_approval,
        :is_active,
        :display_order
      ).merge(court_type_id: court_type_id)

      result = Courts::CreateService.call(params: court_params)
      return Failure(result.error) unless result.success?

      @court = result.data
      json_data = serialize
      Success(court: @court, json: json_data)
    end

    private

    attr_reader :params, :current_user, :court, :venue

    def authorize
      VenuePolicy.new(current_user, venue).update?
    end

    def find_court_type_id(sport_type_name)
      court_type = CourtType.where("lower(name) = ?", sport_type_name.to_s.downcase).first
      court_type&.id
    end

    def serialize
      Api::V0::CourtBlueprint.render_as_hash(court, view: :detailed)
    end
  end
end
