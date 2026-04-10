class VenueOperatingHour < ApplicationRecord
  DAYS_OF_WEEK = {
    0 => "Sunday",
    1 => "Monday",
    2 => "Tuesday",
    3 => "Wednesday",
    4 => "Thursday",
    5 => "Friday",
    6 => "Saturday"
  }.freeze

  belongs_to :venue

  validates :day_of_week, presence: true, inclusion: { in: 0..6 }
  validates :day_of_week, uniqueness: { scope: :venue_id }
  validates :opens_at, presence: true, unless: :is_closed?
  validates :closes_at, presence: true, unless: :is_closed?

  validate :closes_after_opens

  scope :open_days, -> { where(is_closed: false) }
  scope :closed_days, -> { where(is_closed: true) }

  def day_name
    DAYS_OF_WEEK[day_of_week]
  end

  def formatted_hours
    return "Closed" if is_closed?
    "#{opens_at.strftime('%I:%M %p')} - #{closes_at.strftime('%I:%M %p')}"
  end

  private

  def closes_after_opens
    return if is_closed? || opens_at.blank? || closes_at.blank?

    if closes_at <= opens_at
      errors.add(:closes_at, "must be after opening time")
    end
  end
end
