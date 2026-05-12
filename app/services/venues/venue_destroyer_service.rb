# frozen_string_literal: true

module Venues
  class VenueDestroyerService < BaseService
    def call(venue:)
      # Check for dependencies
      # if venue.courts.exists?
      #   return failure("Cannot delete venue with existing courts")
      # end

      # TODO: think what to do with existing bookings. Should we delete them or prevent deletion if there are active bookings?
      # if venue.bookings.exists?
      #   return failure("Cannot delete venue with existing bookings")
      # end
      ActiveRecord::Base.transaction do
        venue.destroy!
      end
      success(true)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end
  end
end
