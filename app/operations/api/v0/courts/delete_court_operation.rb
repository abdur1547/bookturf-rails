# frozen_string_literal: true

module Api::V0::Courts
  class DeleteCourtOperation < BaseOperation
    contract do
      params do
        required(:id).filled
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @court = find_court(params[:id])
      return Failure(:not_found) unless @court
      return Failure(:forbidden) unless authorize?

      result = Courts::DeleteService.call(court: @court)
      return Failure(result.error) unless result.success?

      json_data = serialize
      Success(court: @court, json: json_data)
    end

    private

    attr_reader :params, :current_user, :court

    def find_court(id)
      Court.find_by(id: id)
    end

    def authorize?
      CourtPolicy.new(current_user, court).destroy?
    end

    def serialize
      { message: "Court deleted successfully" }
    end
  end
end
