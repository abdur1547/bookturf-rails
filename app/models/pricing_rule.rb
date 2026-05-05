class PricingRule < ApplicationRecord
  belongs_to :venue
  belongs_to :court

  enum :day_of_week, {
    monday: 0,
    tuesday: 1,
    wednesday: 2,
    thursday: 3,
    friday: 4,
    saturday: 5,
    sunday: 6,
    all_days: 7,
    weekdays: 8,
    weekends: 9
  }

  validates :name, presence: true
  validates :price_per_hour, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :priority, presence: true, numericality: { only_integer: true }

  validate :end_time_after_start_time
  validate :end_date_after_start_date

  scope :active, -> { where(is_active: true) }
  scope :for_court, ->(court) { where(court: court) }
  scope :by_priority, -> { order(priority: :desc) }

  # Scope to find rules that apply to a specific date/time
  scope :applicable_at, ->(datetime) do
    active.where(
      '(day_of_week IS NULL OR day_of_week = ?) AND
       (start_time IS NULL OR start_time <= ?) AND
       (end_time IS NULL OR end_time > ?) AND
       (start_date IS NULL OR start_date <= ?) AND
       (end_date IS NULL OR end_date >= ?)',
      datetime.wday,
      datetime.strftime("%H:%M:%S"),
      datetime.strftime("%H:%M:%S"),
      datetime.to_date,
      datetime.to_date
    )
  end

  # Find the applicable price for a given court at a specific time
  def self.price_for(court, datetime)
    rule = for_court(court)
           .applicable_at(datetime)
           .by_priority
           .first

    rule&.price_per_hour || 0
  end

  def applies_to?(datetime)
    return false unless is_active?

    # Check day of week
    return false if day_of_week.present? && datetime.wday != day_of_week

    # Check time range
    if start_time.present? && end_time.present?
      time_of_day = datetime.strftime("%H:%M:%S")
      return false if time_of_day < start_time.strftime("%H:%M:%S")
      return false if time_of_day >= end_time.strftime("%H:%M:%S")
    end

    # Check date range
    return false if start_date.present? && datetime.to_date < start_date
    return false if end_date.present? && datetime.to_date > end_date

    true
  end

  def time_range
    return "All day" if start_time.blank? || end_time.blank?
    "#{start_time.strftime('%I:%M %p')} - #{end_time.strftime('%I:%M %p')}"
  end

  def day_name
    day_of_week.humanize
  end

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?

    if end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be after start date")
    end
  end
end
