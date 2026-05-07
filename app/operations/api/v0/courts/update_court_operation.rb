# frozen_string_literal: true

module Api::V0::Courts
  class UpdateCourtOperation < BaseOperation
    contract do
      params do
        required(:id).filled
        optional(:court_type_id).maybe(:integer)
        optional(:name).maybe(:string)
        optional(:description).maybe(:string)
        optional(:slot_interval).maybe(:integer)
        optional(:requires_approval).maybe(:bool)
        optional(:is_active).maybe(:bool)
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @court = find_court(params[:id])
      return Failure(:not_found) unless @court
      return Failure(:forbidden) unless authorize

      court_params = params.slice(
        :name,
        :description,
        :slot_interval,
        :requires_approval,
        :is_active,
        :court_type_id
      ).compact

      result = Courts::UpdateService.call(court: @court, params: court_params)
      return Failure(result.error) unless result.success?

      @court = result.data
      json_data = serialize
      Success(court: @court, json: json_data)
    end

    private

    attr_reader :params, :current_user, :court

    def find_court(id)
      Court.find_by(id: id)
    end

    def authorize
      CourtPolicy.new(current_user, court).update?
    end

    def serialize
      Api::V0::CourtBlueprint.render_as_hash(court)
    end
  end
end
