# frozen_string_literal: true

module Venues
  class OperatingHoursValidatorService < BaseService
    def call(operating_hours:, is_update: false)
      @operating_hours = operating_hours
      return failure("Operating hours must be an array") unless operating_hours.is_a?(Array)

      unless is_update
        result = validate_all_seven_days_are_present
        return result unless result.success?
      end

      operating_hours.each do |hours|
        validation_result = validate_single_day(hours)
        return validation_result unless validation_result.success?
      end

      success(true)
    end

    private
    attr_reader :operating_hours

    def validate_all_seven_days_are_present
      days_provided = operating_hours.map { |h| h[:day_of_week] || h["day_of_week"] }.compact.sort
      expected_days = (0..6).to_a
      return failure("All 7 days must be provided (0-6)") unless days_provided == expected_days

      success(true)
    end

    def validate_single_day(hours)
      day = hours[:day_of_week] || hours["day_of_week"]
      is_closed = hours[:is_closed] || hours["is_closed"]
      opens_at = hours[:opens_at] || hours["opens_at"]
      closes_at = hours[:closes_at] || hours["closes_at"]

      # If not closed, must have opens_at and closes_at
      unless is_closed
        return failure("Day #{day}: opens_at is required when not closed") if opens_at.blank?
        return failure("Day #{day}: closes_at is required when not closed") if closes_at.blank?

        # Validate time format and order
        if opens_at.present? && closes_at.present?
          begin
            opens = Time.parse(opens_at.to_s)
            closes = Time.parse(closes_at.to_s)

            # Handle past-midnight closing times (e.g., opens 08:00, closes 00:00 next day)
            # If closes_at is earlier than opens_at, assume it's next day
            closes += 1.day if closes <= opens

            # After adjusting for next day, check if it's actually valid
            # (e.g., opens 23:00, closes 09:00 is valid - 10 hour shift)
            if closes == opens
              return failure("Day #{day}: closes_at must be different from opens_at")
            end
          rescue ArgumentError
            return failure("Day #{day}: Invalid time format")
          end
        end
      end

      success(true)
    end
  end
end
