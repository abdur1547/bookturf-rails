class VenueSetting < ApplicationRecord
  belongs_to :venue

  validates :minimum_slot_duration, presence: true, numericality: { greater_than: 0 }
  validates :maximum_slot_duration, presence: true, numericality: { greater_than: 0 }
  validates :slot_interval, presence: true, numericality: { greater_than: 0 }
  validates :timezone, presence: true
  validates :currency, presence: true

  validate :maximum_greater_than_minimum

  def slot_durations
    (minimum_slot_duration..maximum_slot_duration).step(slot_interval).to_a
  end

  private

  def maximum_greater_than_minimum
    return unless minimum_slot_duration.present? && maximum_slot_duration.present?

    if maximum_slot_duration < minimum_slot_duration
      errors.add(:maximum_slot_duration, "must be greater than or equal to minimum")
    end
  end
end
