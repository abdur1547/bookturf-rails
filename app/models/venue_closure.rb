class VenueClosure < ApplicationRecord
  belongs_to :venue
  belongs_to :created_by, class_name: "User", optional: true

  validates :title, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true

  validate :end_time_after_start_time

  scope :active, -> { where("end_time > ?", Time.current) }
  scope :past, -> { where("end_time <= ?", Time.current) }
  scope :current, -> { where("start_time <= ? AND end_time > ?", Time.current, Time.current) }
  scope :upcoming, -> { where("start_time > ?", Time.current).order(:start_time) }
  scope :overlapping, ->(start_time, end_time) do
    where("start_time < ? AND end_time > ?", end_time, start_time)
  end

  def self.venue_closed?(venue, start_time, end_time)
    where(venue: venue)
      .overlapping(start_time, end_time)
      .exists?
  end

  def active?
    end_time > Time.current
  end

  def past?
    end_time <= Time.current
  end

  def current?
    start_time <= Time.current && end_time > Time.current
  end

  def duration_hours
    ((end_time - start_time) / 1.hour).round(1)
  end

  def formatted_date_range
    if start_time.to_date == end_time.to_date
      "#{start_time.strftime('%B %d, %Y')} (#{formatted_time_range})"
    else
      "#{start_time.strftime('%b %d, %I:%M %p')} - #{end_time.strftime('%b %d, %I:%M %p')}"
    end
  end

  def formatted_time_range
    "#{start_time.strftime('%I:%M %p')} - #{end_time.strftime('%I:%M %p')}"
  end

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?
    errors.add(:end_time, "must be after start time") if end_time <= start_time
  end
end
