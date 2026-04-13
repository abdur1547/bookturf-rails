# frozen_string_literal: true

module Api::V0
  class VenuesController < ApiController
    skip_before_action :authenticate_user!, only: [ :index, :show ]

    # GET /api/v0/venues
    def index
      result = Api::V0::Venues::ListVenuesOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # GET /api/v0/venues/:id
    def show
      result = Api::V0::Venues::GetVenueOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # POST /api/v0/venues
    def create
      result = Api::V0::Venues::CreateVenueOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result, :created)
    end

    # PATCH/PUT /api/v0/venues/:id
    def update
      result = Api::V0::Venues::UpdateVenueOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # DELETE /api/v0/venues/:id
    def destroy
      result = Api::V0::Venues::DeleteVenueOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    private

    def handle_operation_response(result, success_status = :ok)
      if result.success
        render json: {
          success: true,
          data: result.value[:json]
        }, status: success_status
      else
        handle_operation_failure(result)
      end
    end

    def handle_operation_failure(result)
      errors = result.errors

      case errors
      when :unauthorized
        forbidden_response("You are not authorized to perform this action")
      else
        unprocessable_entity(errors)
      end
    end
  end
end
