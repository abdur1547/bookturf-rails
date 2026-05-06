# frozen_string_literal: true

module Api::V0
  class BookingsController < ApiController
    # GET /api/v0/bookings
    def index
      result = Api::V0::Bookings::ListBookingsOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # TODO: add my_bookings endpoint to list only bookings for current_user

    # GET /api/v0/bookings/:id
    def show
      result = Api::V0::Bookings::GetBookingOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # POST /api/v0/bookings
    def create
      result = Api::V0::Bookings::CreateBookingOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result, :created)
    end

    # PATCH/PUT /api/v0/bookings/:id
    def update
      result = Api::V0::Bookings::UpdateBookingOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # DELETE /api/v0/bookings/:id
    def destroy
      result = Api::V0::Bookings::DeleteBookingOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # POST /api/v0/bookings/availability
    def availability
      result = Api::V0::Bookings::CheckAvailabilityOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # PATCH /api/v0/bookings/:id/cancel
    def cancel
      result = Api::V0::Bookings::CancelBookingOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # PATCH /api/v0/bookings/:id/check_in
    def check_in
      result = Api::V0::Bookings::CheckInBookingOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # PATCH /api/v0/bookings/:id/no_show
    def no_show
      result = Api::V0::Bookings::MarkNoShowBookingOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # PATCH /api/v0/bookings/:id/complete
    def complete
      result = Api::V0::Bookings::CompleteBookingOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # PATCH /api/v0/bookings/:id/reschedule
    def reschedule
      result = Api::V0::Bookings::RescheduleBookingOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end
  end
end
