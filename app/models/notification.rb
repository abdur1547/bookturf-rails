class Notification < ApplicationRecord
  TYPES = %w[
    booking_confirmed
    booking_reminder
    booking_cancelled
    booking_modified
    court_closure
    payment_due
    venue_announcement
    system_alert
  ].freeze

  PRIORITIES = %w[low normal high urgent].freeze

  belongs_to :user
  belongs_to :venue, optional: true
  belongs_to :booking, optional: true

  validates :notification_type, presence: true, inclusion: { in: TYPES }
  validates :title, presence: true
  validates :message, presence: true
  validates :priority, inclusion: { in: PRIORITIES }

  before_create :set_sent_at

  scope :unread, -> { where(is_read: false) }
  scope :read, -> { where(is_read: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_priority, -> { order(Arel.sql("CASE priority WHEN 'urgent' THEN 1 WHEN 'high' THEN 2 WHEN 'normal' THEN 3 ELSE 4 END")) }
  scope :for_type, ->(type) { where(notification_type: type) }

  # Create a booking confirmation notification
  def self.booking_confirmed(booking)
    create!(
      user: booking.user,
      venue: booking.venue,
      booking: booking,
      notification_type: "booking_confirmed",
      title: "Booking Confirmed",
      message: "Your booking for #{booking.court_name} on #{booking.formatted_date} at #{booking.formatted_time_slot} has been confirmed.",
      action_url: "/bookings/#{booking.id}",
      priority: "normal"
    )
  end

  # Create a booking reminder notification
  def self.booking_reminder(booking)
    create!(
      user: booking.user,
      venue: booking.venue,
      booking: booking,
      notification_type: "booking_reminder",
      title: "Booking Reminder",
      message: "Reminder: Your booking for #{booking.court_name} is scheduled for #{booking.formatted_date} at #{booking.formatted_time_slot}.",
      action_url: "/bookings/#{booking.id}",
      priority: "high"
    )
  end

  # Create a booking cancelled notification
  def self.booking_cancelled(booking, reason: nil)
    message = "Your booking for #{booking.court_name} on #{booking.formatted_date} has been cancelled."
    message += " Reason: #{reason}" if reason.present?

    create!(
      user: booking.user,
      venue: booking.venue,
      booking: booking,
      notification_type: "booking_cancelled",
      title: "Booking Cancelled",
      message: message,
      priority: "high"
    )
  end

  # Create a venue announcement notification
  def self.venue_announcement(user, venue, title, message)
    create!(
      user: user,
      venue: venue,
      notification_type: "venue_announcement",
      title: title,
      message: message,
      priority: "normal"
    )
  end

  def mark_as_read!
    update!(is_read: true, read_at: Time.current)
  end

  def mark_as_unread!
    update!(is_read: false, read_at: nil)
  end

  def read?
    is_read
  end

  def unread?
    !is_read
  end

  def urgent?
    priority == "urgent"
  end

  def high_priority?
    priority == "high"
  end

  def icon
    case notification_type
    when "booking_confirmed" then "✅"
    when "booking_reminder" then "🔔"
    when "booking_cancelled" then "❌"
    when "booking_modified" then "✏️"
    when "court_closure" then "🔒"
    when "payment_due" then "💰"
    when "venue_announcement" then "📢"
    when "system_alert" then "⚠️"
    else "📨"
    end
  end

  def priority_class
    case priority
    when "urgent" then "text-red-600"
    when "high" then "text-orange-600"
    when "normal" then "text-blue-600"
    else "text-gray-600"
    end
  end

  private

  def set_sent_at
    self.sent_at ||= Time.current
  end
end
