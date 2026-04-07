# Database Implementation - Phase 6: Court Closures & Notifications

**Phase**: 6 of 6  
**Status**: Final Features  
**Dependencies**: Phases 1-5 (All previous phases)  
**Estimated Time**: 2-3 days

---

## Overview

This final phase adds court maintenance scheduling and user notifications. Courts can be blocked for maintenance, and users receive notifications about their bookings and venue announcements.

**What you'll build:**
- Court closure scheduling (maintenance, special events)
- In-app notification system
- Notification types (booking confirmations, reminders, announcements)
- Court availability checking with closure awareness

---

## Tables in This Phase

### 1. court_closures (Block courts for maintenance/events)
### 2. notifications (In-app user notifications)

---

## Rails Migrations

### Migration 1: Create Court Closures

```ruby
class CreateCourtClosures < ActiveRecord::Migration[7.1]
  def change
    create_table :court_closures do |t|
      t.references :court, null: false, foreign_key: true
      t.references :venue, null: false, foreign_key: true # Denormalized
      
      t.string :title, null: false
      t.text :description
      
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      
      t.references :created_by, foreign_key: { to_table: :users }
      
      t.timestamps
    end
    
    # Indexes
    add_index :court_closures, [:court_id, :start_time, :end_time]
    add_index :court_closures, [:venue_id, :start_time]
    add_index :court_closures, [:start_time, :end_time]
    
    # Check constraint
    add_check_constraint :court_closures,
      'end_time > start_time',
      name: 'closure_end_after_start'
  end
end
```

### Migration 2: Create Notifications

```ruby
class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :venue, null: true, foreign_key: true
      t.references :booking, null: true, foreign_key: true
      
      t.string :type, null: false
      t.string :title, null: false
      t.text :message, null: false
      t.string :action_url
      
      t.boolean :is_read, default: false, null: false
      t.datetime :read_at
      t.string :priority, default: 'normal', null: false
      t.datetime :sent_at
      
      t.timestamps
    end
    
    # Indexes
    add_index :notifications, [:user_id, :is_read]
    add_index :notifications, [:user_id, :created_at]
    add_index :notifications, :type
    add_index :notifications, :priority
  end
end
```

---

## Models

### app/models/court_closure.rb

```ruby
class CourtClosure < ApplicationRecord
  # ============================================================================
  # ASSOCIATIONS
  # ============================================================================
  belongs_to :court
  belongs_to :venue
  belongs_to :created_by, class_name: 'User', optional: true
  
  # ============================================================================
  # VALIDATIONS
  # ============================================================================
  validates :title, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  
  validate :end_time_after_start_time
  validate :no_overlapping_bookings
  
  # ============================================================================
  # CALLBACKS
  # ============================================================================
  before_validation :set_venue, if: -> { court.present? && venue.blank? }
  
  # ============================================================================
  # SCOPES
  # ============================================================================
  scope :active, -> { where('end_time > ?', Time.current) }
  scope :past, -> { where('end_time <= ?', Time.current) }
  scope :current, -> { where('start_time <= ? AND end_time > ?', Time.current, Time.current) }
  scope :upcoming, -> { where('start_time > ?', Time.current).order(:start_time) }
  scope :for_court, ->(court) { where(court: court) }
  scope :on_date, ->(date) { where('DATE(start_time) = ? OR DATE(end_time) = ?', date, date) }
  
  # Scope to find closures that overlap with a time range
  scope :overlapping, ->(start_time, end_time) do
    where('start_time < ? AND end_time > ?', end_time, start_time)
  end
  
  # ============================================================================
  # CLASS METHODS
  # ============================================================================
  
  # Check if a court is closed during a specific time range
  def self.court_closed?(court, start_time, end_time)
    for_court(court)
      .overlapping(start_time, end_time)
      .exists?
  end
  
  # ============================================================================
  # INSTANCE METHODS
  # ============================================================================
  
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
  
  def set_venue
    self.venue = court.venue
  end
  
  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?
    
    if end_time <= start_time
      errors.add(:end_time, 'must be after start time')
    end
  end
  
  def no_overlapping_bookings
    return if court.blank? || start_time.blank? || end_time.blank?
    
    overlapping_bookings = Booking.where(court: court)
                                  .confirmed
                                  .where('start_time < ? AND end_time > ?', end_time, start_time)
    
    if overlapping_bookings.exists?
      errors.add(:base, "Cannot create closure: #{overlapping_bookings.count} confirmed booking(s) exist during this time")
    end
  end
end
```

### app/models/notification.rb

```ruby
class Notification < ApplicationRecord
  # ============================================================================
  # CONSTANTS
  # ============================================================================
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
  
  # ============================================================================
  # ASSOCIATIONS
  # ============================================================================
  belongs_to :user
  belongs_to :venue, optional: true
  belongs_to :booking, optional: true
  
  # ============================================================================
  # VALIDATIONS
  # ============================================================================
  validates :type, presence: true, inclusion: { in: TYPES }
  validates :title, presence: true
  validates :message, presence: true
  validates :priority, inclusion: { in: PRIORITIES }
  
  # ============================================================================
  # CALLBACKS
  # ============================================================================
  before_create :set_sent_at
  
  # ============================================================================
  # SCOPES
  # ============================================================================
  scope :unread, -> { where(is_read: false) }
  scope :read, -> { where(is_read: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_priority, -> { order(Arel.sql("CASE priority WHEN 'urgent' THEN 1 WHEN 'high' THEN 2 WHEN 'normal' THEN 3 ELSE 4 END")) }
  scope :for_type, ->(type) { where(type: type) }
  
  # ============================================================================
  # CLASS METHODS
  # ============================================================================
  
  # Create a booking confirmation notification
  def self.booking_confirmed(booking)
    create!(
      user: booking.user,
      venue: booking.venue,
      booking: booking,
      type: 'booking_confirmed',
      title: 'Booking Confirmed',
      message: "Your booking for #{booking.court_name} on #{booking.formatted_date} at #{booking.formatted_time_slot} has been confirmed.",
      action_url: "/bookings/#{booking.id}",
      priority: 'normal'
    )
  end
  
  # Create a booking reminder notification
  def self.booking_reminder(booking)
    create!(
      user: booking.user,
      venue: booking.venue,
      booking: booking,
      type: 'booking_reminder',
      title: 'Booking Reminder',
      message: "Reminder: Your booking for #{booking.court_name} is scheduled for #{booking.formatted_date} at #{booking.formatted_time_slot}.",
      action_url: "/bookings/#{booking.id}",
      priority: 'high'
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
      type: 'booking_cancelled',
      title: 'Booking Cancelled',
      message: message,
      priority: 'high'
    )
  end
  
  # Create a venue announcement notification
  def self.venue_announcement(user, venue, title, message)
    create!(
      user: user,
      venue: venue,
      type: 'venue_announcement',
      title: title,
      message: message,
      priority: 'normal'
    )
  end
  
  # ============================================================================
  # INSTANCE METHODS
  # ============================================================================
  
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
    priority == 'urgent'
  end
  
  def high_priority?
    priority == 'high'
  end
  
  def icon
    case type
    when 'booking_confirmed' then '✅'
    when 'booking_reminder' then '🔔'
    when 'booking_cancelled' then '❌'
    when 'booking_modified' then '✏️'
    when 'court_closure' then '🔒'
    when 'payment_due' then '💰'
    when 'venue_announcement' then '📢'
    when 'system_alert' then '⚠️'
    else '📨'
    end
  end
  
  def priority_class
    case priority
    when 'urgent' then 'text-red-600'
    when 'high' then 'text-orange-600'
    when 'normal' then 'text-blue-600'
    else 'text-gray-600'
    end
  end
  
  private
  
  def set_sent_at
    self.sent_at ||= Time.current
  end
end
```

### Update app/models/booking.rb

Add notification triggers:

```ruby
# Add to the after_create callback section:
after_create :send_confirmation_notification

# Add to the instance methods section:
def cancel!(reason: nil, cancelled_by: nil)
  transaction do
    update!(
      status: 'cancelled',
      cancelled_at: Time.current,
      cancelled_by: cancelled_by,
      cancellation_reason: reason
    )
    
    # Send cancellation notification
    Notification.booking_cancelled(self, reason: reason)
  end
end

private

def send_confirmation_notification
  Notification.booking_confirmed(self)
end
```

### Update app/models/court.rb

Add closure awareness to availability check:

```ruby
# Update the available_at? method:
def available_at?(start_time, end_time)
  return false unless is_active?
  
  # Check closures
  return false if CourtClosure.court_closed?(self, start_time, end_time)
  
  # Check bookings
  return false unless Booking.slot_available?(self, start_time, end_time)
  
  true
end
```

---

## Seed Data

**File**: `db/seeds/06_closures_notifications.rb`

```ruby
puts "🌱 Seeding Phase 6: Court Closures & Notifications..."

venue = Venue.first
courts = Court.all
admin = User.find_by(email: 'owner@example.com')

unless venue && courts.any? && admin
  puts "  ⚠️  Missing required data. Run previous phase seeds first."
  exit
end

# ============================================================
# COURT CLOSURES
# ============================================================

# Today's maintenance
today = Date.current
closure1 = CourtClosure.create!(
  court: courts.first,
  venue: venue,
  title: 'Floor Maintenance',
  description: 'Annual floor polishing and maintenance',
  start_time: today.in_time_zone.change(hour: 6),
  end_time: today.in_time_zone.change(hour: 9),
  created_by: admin
)
puts "  ✅ Created court closure: #{closure1.title} (#{closure1.formatted_date_range})"

# Tomorrow's closure
tomorrow = Date.tomorrow
closure2 = CourtClosure.create!(
  court: courts.second,
  venue: venue,
  title: 'Light Fixture Repair',
  description: 'Replacing damaged ceiling lights',
  start_time: tomorrow.in_time_zone.change(hour: 13),
  end_time: tomorrow.in_time_zone.change(hour: 15),
  created_by: admin
)
puts "  ✅ Created court closure: #{closure2.title} (#{closure2.formatted_date_range})"

# Weekend closure for special event
weekend = Date.current.next_occurring(:saturday)
closure3 = CourtClosure.create!(
  court: courts.last,
  venue: venue,
  title: 'Private Tournament',
  description: 'Court reserved for inter-school tournament',
  start_time: weekend.in_time_zone.change(hour: 9),
  end_time: weekend.in_time_zone.change(hour: 18),
  created_by: admin
)
puts "  ✅ Created court closure: #{closure3.title} (#{closure3.formatted_date_range})"

# ============================================================
# NOTIFICATIONS
# ============================================================

# Booking confirmation notifications (created automatically via callback)
booking_count = Notification.where(type: 'booking_confirmed').count
puts "  ✅ #{booking_count} booking confirmation notifications (auto-generated)"

# Create venue announcements for all users with bookings
users_with_bookings = User.joins(:bookings).distinct
users_with_bookings.each do |user|
  Notification.venue_announcement(
    user,
    venue,
    'New Weekend Hours',
    'Starting next month, weekend hours will be extended till midnight. Book your late night slots now!'
  )
end
puts "  ✅ Created #{users_with_bookings.count} venue announcement notifications"

# Create booking reminders for upcoming bookings (in real app, this would be a background job)
upcoming_bookings = Booking.upcoming.where('start_time < ?', 24.hours.from_now)
upcoming_bookings.each do |booking|
  Notification.booking_reminder(booking)
end
puts "  ✅ Created #{upcoming_bookings.count} booking reminder notifications"

puts "\n✅ Phase 6 seeding complete!"
puts "  🔒 Court Closures: #{CourtClosure.count}"
puts "  📬 Notifications: #{Notification.count}"
puts "    - Unread: #{Notification.unread.count}"
puts "    - Read: #{Notification.read.count}"
```

---

## Background Jobs (Optional)

**File**: `app/jobs/send_booking_reminders_job.rb`

```ruby
class SendBookingRemindersJob < ApplicationJob
  queue_as :default

  def perform
    # Send reminders for bookings starting in 1 hour
    upcoming_bookings = Booking.confirmed
                              .where(start_time: 1.hour.from_now..2.hours.from_now)
                              .where.not(id: Notification.where(type: 'booking_reminder').pluck(:booking_id))
    
    upcoming_bookings.each do |booking|
      Notification.booking_reminder(booking)
    end
    
    Rails.logger.info "Sent #{upcoming_bookings.count} booking reminders"
  end
end
```

Schedule this job to run every hour using a scheduler like Sidekiq-Cron or Whenever.

---

## Service Object for Available Slots

**File**: `app/services/slot_availability_service.rb`

```ruby
class SlotAvailabilityService
  def initialize(court:, date:)
    @court = court
    @venue = court.venue
    @date = date
    @settings = @venue.venue_setting
  end
  
  def available_slots
    return [] unless @settings
    
    # Get operating hours for this day
    day_of_week = @date.wday
    operating_hours = @venue.venue_operating_hours.find_by(day_of_week: day_of_week)
    
    return [] if operating_hours.nil? || operating_hours.is_closed?
    
    # Generate time slots
    slots = generate_time_slots(operating_hours)
    
    # Filter out booked and closed slots
    slots.select { |slot| slot_available?(slot[:start_time], slot[:end_time]) }
  end
  
  private
  
  def generate_time_slots(operating_hours)
    slots = []
    current_time = @date.in_time_zone.change(
      hour: operating_hours.opens_at.hour,
      min: operating_hours.opens_at.min
    )
    
    closing_time = @date.in_time_zone.change(
      hour: operating_hours.closes_at.hour,
      min: operating_hours.closes_at.min
    )
    
    while current_time < closing_time
      [@settings.minimum_slot_duration, @settings.maximum_slot_duration].each do |duration|
        next if duration % @settings.slot_interval != 0
        
        end_time = current_time + duration.minutes
        
        if end_time <= closing_time
          price = PricingRule.price_for(@court.court_type, current_time)
          
          slots << {
            start_time: current_time,
            end_time: end_time,
            duration: duration,
            price: price,
            formatted: "#{current_time.strftime('%I:%M %p')} - #{end_time.strftime('%I:%M %p')}"
          }
        end
      end
      
      current_time += @settings.slot_interval.minutes
    end
    
    slots.uniq { |slot| [slot[:start_time], slot[:end_time]] }
  end
  
  def slot_available?(start_time, end_time)
    # Check if court is open for bookings
    return false unless @court.is_active?
    
    # Check for closures
    return false if CourtClosure.court_closed?(@court, start_time, end_time)
    
    # Check for existing bookings
    Booking.slot_available?(@court, start_time, end_time)
  end
end
```

---

## Testing

**File**: `spec/models/court_closure_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe CourtClosure, type: :model do
  let(:court) { create(:court) }
  let(:start_time) { 1.day.from_now.change(hour: 9) }
  let(:end_time) { 1.day.from_now.change(hour: 12) }
  
  describe 'validations' do
    it 'prevents overlapping with confirmed bookings' do
      # Create a booking in the time range
      create(:booking, court: court, start_time: start_time, end_time: end_time, status: 'confirmed')
      
      closure = CourtClosure.new(
        court: court,
        title: 'Maintenance',
        start_time: start_time,
        end_time: end_time
      )
      
      expect(closure).not_to be_valid
      expect(closure.errors[:base]).to include(match(/confirmed booking/))
    end
  end
  
  describe '.court_closed?' do
    it 'returns true when court has closure during time range' do
      create(:court_closure, court: court, start_time: start_time, end_time: end_time)
      
      expect(CourtClosure.court_closed?(court, start_time + 30.minutes, end_time - 30.minutes)).to be true
    end
    
    it 'returns false when court has no closures' do
      expect(CourtClosure.court_closed?(court, start_time, end_time)).to be false
    end
  end
end
```

---

## Checklist

Phase 6 complete when:

- [ ] Court closures migration run successfully
- [ ] Notifications migration run successfully
- [ ] Can create court closures
- [ ] Closures prevent overlapping bookings
- [ ] Court availability checks closures
- [ ] Notifications created for bookings
- [ ] Can mark notifications as read/unread
- [ ] Unread notification count works
- [ ] Available slots service excludes closures
- [ ] Past closures queryable
- [ ] Tests passing

---

## 🎉 Congratulations!

You've completed all 6 phases of the database implementation!

### What You've Built:
✅ User authentication and profiles  
✅ Venue management with settings and operating hours  
✅ Courts with sport types and dynamic pricing  
✅ Role-based permissions system  
✅ Complete booking system with audit trail  
✅ Court closures and notifications  

### Next Steps:
1. **API Development**: Build RESTful APIs for frontend
2. **Frontend Integration**: Connect Angular app to backend
3. **Background Jobs**: Set up reminder emails/SMS
4. **Reporting**: Build analytics and reports
5. **Deployment**: Deploy to production (Kamal)

---

*Last Updated: 2026-04-07*
