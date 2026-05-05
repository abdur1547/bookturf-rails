# frozen_string_literal: true

module Api::V0::Bookings
  class ListBookingsOperation < BaseOperation
    contract do
      params do
        optional(:status).maybe(:string)
        optional(:user_id).maybe(:integer)
        optional(:court_id).maybe(:integer)
        optional(:from_date).maybe(:string)
        optional(:to_date).maybe(:string)
        optional(:page).maybe(:integer)
        optional(:per_page).maybe(:integer)
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      return Failure(:forbidden) unless authorize?

      @bookings = accessible_bookings
      @bookings = filter_bookings(@bookings)
      @bookings = paginate(@bookings)

      Success(bookings: @bookings, json: serialize)
    end

    private

    attr_reader :params, :current_user, :bookings

    def authorize?
      BookingPolicy.new(current_user, Booking).index?
    end

    def accessible_bookings
      if current_user.super_admin?
        Booking.all
      else
        venue_ids = (current_user.owned_venues.pluck(:id) + current_user.venues.pluck(:id)).uniq
        venue_ids.any? ? Booking.where(venue_id: venue_ids) : Booking.where(user: current_user)
      end
    end

    def filter_bookings(bookings)
      bookings = bookings.where(status: params[:status]) if params[:status].present?
      bookings = bookings.where(user_id: params[:user_id]) if params[:user_id].present?
      bookings = bookings.where(court_id: params[:court_id]) if params[:court_id].present?
      bookings = filter_date_range(bookings)
      bookings.order(start_time: :asc)
    end

    def filter_date_range(bookings)
      if params[:from_date].present?
        from_date = parse_date(params[:from_date])
        bookings = bookings.where("start_time >= ?", from_date.beginning_of_day) if from_date
      end

      if params[:to_date].present?
        to_date = parse_date(params[:to_date])
        bookings = bookings.where("start_time <= ?", to_date.end_of_day) if to_date
      end

      bookings
    end

    def parse_date(value)
      Date.parse(value)
    rescue ArgumentError
      nil
    end

    def paginate(bookings)
      page = params[:page].to_i.positive? ? params[:page].to_i : 1
      per_page = params[:per_page].to_i.positive? ? params[:per_page].to_i : 25
      bookings.limit(per_page).offset((page - 1) * per_page)
    end

    def serialize
      Api::V0::BookingBlueprint.render_as_hash(bookings, view: :list)
    end
  end
end
