# frozen_string_literal: true

module Venues
  class AvailabilityService < BaseService
    def call(
      venue:,
      start_date:,
      end_date:,
      duration_minutes:,
      court_type_id: nil,
      court_id: nil,
      include_booked: false
    )
      @venue = venue
      @start_date = start_date
      @end_date = end_date
      @duration_minutes = duration_minutes
      @court_type_id = court_type_id
      @court_id = court_id
      @include_booked = include_booked
      @settings = venue.venue_setting
      @time_zone = ActiveSupport::TimeZone[@settings.timezone]

      return failure("Venue settings are required") unless @settings

      courts = venue.courts.active
      courts = courts.where(court_type_id: court_type_id) if court_type_id.present?
      courts = courts.where(id: court_id) if court_id.present?

      availability = courts.map do |court|
        {
          court_id: court.id,
          court_name: court.full_name,
          slots: build_slots_for_court(court)
        }
      end

      success(
        venue_id: venue.id,
        start_date: start_date.to_s,
        end_date: end_date.to_s,
        timezone: @settings.timezone,
        court_availability: availability
      )
    end

    private

    attr_reader :venue, :settings, :start_date, :end_date,
                :duration_minutes, :court_type_id, :court_id,
                :include_booked, :time_zone

    def build_slots_for_court(court)
      return [] if time_zone.nil?

      slots = []
      date_range.each do |date|
        operating_hours = venue.operating_hours_for(date.wday)
        next if operating_hours.nil? || operating_hours.is_closed?

        window = availability_window(date, operating_hours)
        next unless window

        slots.concat(build_slots_for_window(court, window[:start], window[:end]))
      end

      slots
    end

    def date_range
      @date_range ||= (start_date..end_date).to_a
    end

    def availability_window(date, operating_hours)
      Time.use_zone(time_zone) do
        open_time = local_datetime(date, operating_hours.opens_at)
        close_time = local_datetime(date, operating_hours.closes_at)
        close_time += 1.day if operating_hours.closes_at <= operating_hours.opens_at

        { start: open_time, end: close_time }
      end
    end

    def local_datetime(date, time_value)
      hour, minute = if time_value.respond_to?(:hour)
                       [ time_value.hour, time_value.min ]
      else
                       time_value
      end

      Time.use_zone(time_zone) do
        Time.zone.local(date.year, date.month, date.day, hour, minute)
      end
    end

    def build_slots_for_window(court, window_start, window_end)
      slots = []
      interval = settings.slot_interval.minutes
      current_start = window_start

      while (current_start + duration_minutes.minutes) <= window_end
        current_end = current_start + duration_minutes.minutes
        available = slot_available?(court, current_start, current_end)
        slot = build_slot(court, current_start, current_end, available)
        slots << slot if include_booked || slot[:available]
        current_start += interval
      end

      slots
    end

    def slot_available?(court, start_time, end_time)
      Booking.slot_available?(court, start_time, end_time) && !closure_conflict?(court, start_time, end_time)
    end

    def build_slot(court, start_time, end_time, available)
      booking_status = slot_booking_status(court, start_time, end_time)
      booked = !available

      {
        start_time: start_time.iso8601,
        end_time: end_time.iso8601,
        duration_minutes: duration_minutes,
        price_per_hour: pricing_price(court, start_time).to_f.to_s,
        total_amount: total_amount(court, start_time).to_f.to_s,
        available: available,
        booked: booked,
        booking_status: booked ? booking_status : nil
      }
    end

    def slot_booking_status(court, start_time, end_time)
      return "confirmed" if booking_conflict?(court, start_time, end_time)
      return "closed" if closure_conflict?(court, start_time, end_time)
      nil
    end

    def booking_conflict?(court, start_time, end_time)
      Booking.confirmed
             .where(court: court)
             .where("start_time < ? AND end_time > ?", end_time, start_time)
             .exists?
    end

    def closure_conflict?(court, start_time, end_time)
      CourtClosure.for_court(court)
                  .overlapping(start_time, end_time)
                  .exists?
    end

    def pricing_price(court, start_time)
      PricingRule.price_for(court.court_type, start_time)
    end

    def total_amount(court, start_time)
      price = pricing_price(court, start_time)
      (price * (duration_minutes / 60.0)).round(2)
    end
  end
end
