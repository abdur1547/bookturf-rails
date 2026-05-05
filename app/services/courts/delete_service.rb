# frozen_string_literal: true

module Courts
  class DeleteService < BaseService
    def call(court:)
      court.destroy!
      success
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed => e
      failure(e.record.errors.full_messages)
    end
  end
end
