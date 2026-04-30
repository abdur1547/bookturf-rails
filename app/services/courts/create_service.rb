# frozen_string_literal: true

module Courts
  class CreateService < BaseService
    def call(params:)
      court = Court.create!(params)
      success(court)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end
  end
end
