# frozen_string_literal: true

module Courts
  class UpdateService < BaseService
    def call(court:, params:)
      ApplicationRecord.transaction do
        court.update!(params)
        success(court)
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end
  end
end
