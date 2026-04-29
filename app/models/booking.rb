class Booking < ApplicationRecord
  include PublicActivity::Model
  tracked owner: ->(controller, model) { controller&.current_user || model.created_by || model.user }

  STATUSES = %w[pending confirmed cancelled no_show].freeze
  PAYMENT_METHODS = %w[cash online card].freeze
  PAYMENT_STATUSES = %w[pending paid refunded].freeze
  CREATED_BY_ROLES = %w[customer staff owner].freeze

  belongs_to :user
  belongs_to :court
  belongs_to :venue
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :cancelled_by, class_name: "User", optional: true
  belongs_to :checked_in_by, class_name: "User", optional: true

  has_many :notifications, dependent: :destroy

  validates :booking_number, presence: true, uniqueness: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :payment_method, inclusion: { in: PAYMENT_METHODS, allow_blank: true }
  validates :payment_status, inclusion: { in: PAYMENT_STATUSES }
  validates :created_by_role, inclusion: { in: CREATED_BY_ROLES }, allow_nil: true
  validates :share_token, uniqueness: true, allow_nil: true
  validate :either_user_or_walk_in_name

  validate :end_time_after_start_time
  validate :no_overlapping_bookings
  validate :duration_matches_time_difference
  validate :within_operating_hours

  before_validation :set_venue, if: -> { court.present? && venue.blank? }
  before_validation :calculate_duration, if: -> { start_time.present? && end_time.present? }
  before_validation :calculate_total_amount, if: :new_record?
  before_validation :generate_booking_number, if: :new_record?
  before_validation :generate_share_token, if: :new_record?
  before_validation :set_created_by_role, if: -> { created_by.present? && created_by_role.blank? }

  scope :confirmed, -> { where(status: "confirmed") }
  scope :completed, -> { where(status: "completed") }
  scope :cancelled, -> { where(status: "cancelled") }
  scope :no_show, -> { where(status: "no_show") }
  scope :active, -> { where(status: %w[confirmed completed]) }

  scope :upcoming, -> { confirmed.where("start_time > ?", Time.current).order(:start_time) }
  scope :past, -> { where("end_time < ?", Time.current).order(start_time: :desc) }
  scope :today, -> { where("DATE(start_time) = ?", Date.current) }
  scope :on_date, ->(date) { where("DATE(start_time) = ?", date) }

  scope :paid, -> { where(payment_status: "paid") }
  scope :unpaid, -> { where(payment_status: "pending") }


  # Check if a time slot is available for booking
  def self.slot_available?(court, start_time, end_time, exclude_booking_id: nil)
    query = where(court: court)
            .confirmed
            .where.not(id: exclude_booking_id)
            .where("start_time < ? AND end_time > ?", end_time, start_time)

    query.empty?
  end

  def confirm!
    update!(status: "confirmed")
    create_activity :confirmed, owner: Current.user || user
  end

  def complete!
    update!(status: "completed")
    create_activity :completed, owner: Current.user || user
  end

  def cancel!(reason: nil, cancelled_by: nil)
    update!(
      status: "cancelled",
      cancelled_at: Time.current,
      cancelled_by: cancelled_by,
      cancellation_reason: reason
    )
    create_activity :cancelled,
                    owner: cancelled_by || Current.user || user,
                    parameters: { reason: reason }
  end

  def mark_no_show!
    update!(status: "no_show")
    create_activity :marked_no_show, owner: Current.user
  end

  def check_in!(checked_in_by:)
    update!(
      checked_in_at: Time.current,
      checked_in_by: checked_in_by
    )
    create_activity :checked_in, owner: checked_in_by
  end

  def mark_paid!(amount: nil, method: "cash")
    update!(
      payment_status: "paid",
      paid_amount: amount || total_amount,
      payment_method: method
    )
    create_activity :marked_paid,
                    owner: Current.user,
                    parameters: { amount: amount || total_amount, method: method }
  end

  def confirmed?
    status == "confirmed"
  end

  def completed?
    status == "completed"
  end

  def cancelled?
    status == "cancelled"
  end

  def paid?
    payment_status == "paid"
  end

  def fully_paid?
    paid? && paid_amount >= total_amount
  end

  def partially_paid?
    paid? && paid_amount < total_amount
  end

  def can_cancel?
    confirmed? && start_time > Time.current
  end

  def duration_hours
    duration_minutes / 60.0
  end

  def formatted_date
    start_time.strftime("%B %d, %Y")
  end

  def formatted_time_slot
    "#{start_time.strftime('%I:%M %p')} - #{end_time.strftime('%I:%M %p')}"
  end

  def customer_name
    user.full_name
  end

  def court_name
    court.full_name
  end

  private

  def set_venue
    self.venue = court.venue
  end

  def calculate_duration
    self.duration_minutes = ((end_time - start_time) / 60).to_i
  end

  def calculate_total_amount
    return if start_time.blank? || court.blank?

    # Use price_at_booking if already set, otherwise calculate
    if price_at_booking.blank?
      hours = duration_hours
      price_per_hour = PricingRule.price_for(court.court_type, start_time)
      self.total_amount = (price_per_hour * hours).round(2)
    else
      self.total_amount = (price_at_booking * duration_hours).round(2)
    end
  end

  def generate_booking_number
    # Format: BK-{venue_slug}-YYYYMMDD-XXXX
    venue_slug = venue&.slug || court&.venue&.slug || "VENUE"
    date_str = Time.current.strftime("%Y%m%d")

    last_booking = Booking.where("booking_number LIKE ?", "BK-#{venue_slug}-#{date_str}-%")
                          .order(:booking_number)
                          .last

    if last_booking
      last_sequence = last_booking.booking_number.split("-").last.to_i
      sequence = last_sequence + 1
    else
      sequence = 1
    end

    self.booking_number = "BK-#{venue_slug}-#{date_str}-#{sequence.to_s.rjust(4, '0')}"
  end

  def generate_share_token
    loop do
      self.share_token = SecureRandom.urlsafe_base64(12)
      break unless Booking.exists?(share_token: share_token)
    end
  end

  def set_created_by_role
    # Default to customer if not set
    self.created_by_role ||= "customer"
  end

  def either_user_or_walk_in_name
    if user.blank? && walk_in_name.blank?
      errors.add(:base, "Either user_id or walk_in_name must be provided")
    end
  end

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?

    if end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end

  def no_overlapping_bookings
    return if court.blank? || start_time.blank? || end_time.blank?

    unless Booking.slot_available?(court, start_time, end_time, exclude_booking_id: id)
      errors.add(:base, "This time slot is already booked")
    end
  end

  def duration_matches_time_difference
    return if start_time.blank? || end_time.blank? || duration_minutes.blank?

    calculated_duration = ((end_time - start_time) / 60).to_i
    if duration_minutes != calculated_duration
      errors.add(:duration_minutes, "does not match time slot duration")
    end
  end

  def within_operating_hours
    return if start_time.blank? || venue.blank?

    day_of_week = start_time.wday
    operating_hours = venue.venue_operating_hours.find_by(day_of_week: day_of_week)

    if operating_hours.nil? || operating_hours.is_closed?
      errors.add(:base, "Venue is closed on this day")
      return
    end

    # Compare times
    start_time_of_day = start_time.strftime("%H:%M:%S")
    end_time_of_day = end_time.strftime("%H:%M:%S")
    opens_at = operating_hours.opens_at.strftime("%H:%M:%S")
    closes_at = operating_hours.closes_at.strftime("%H:%M:%S")

    if start_time_of_day < opens_at || end_time_of_day > closes_at
      errors.add(:base, "Booking must be within operating hours (#{operating_hours.formatted_hours})")
    end
  end
end
