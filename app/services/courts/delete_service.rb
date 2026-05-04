# frozen_string_literal: true

module Courts
  class DeleteService < BaseService
    def call(court:)
      # TODO: add safety check to ensure court has no future bookings before allowing deletion
      court.destroy!
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end
  end
end
