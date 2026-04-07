# Database Implementation - Phase 5: Booking System

**Phase**: 5 of 6  
**Status**: Core Business Logic  
**Dependencies**: Phases 1-4 (Users, Venues, Courts, Roles)  
**Estimated Time**: 4-5 days

---

## Overview

This is the heart of the application - the booking system. Users can reserve courts for specific time slots, track payment status, and view booking history. Includes audit trail for all changes.

**What you'll build:**
- Court booking creation and management
- Double-booking prevention
- Booking status workflow (confirmed → completed/cancelled/no_show)
- Payment tracking (cash-based for MVP)
- Complete audit trail (booking logs)
- Human-readable booking history

---

## Tables in This Phase

### 1. bookings (Core booking records)
### 2. booking_logs (Audit trail for all changes)

---

## Rails Migrations

### Migration 1: Create Bookings

```ruby
class CreateBookings < ActiveRecord::Migration[7.1]
  def change
    create_table :bookings do |t|
      # Unique identifier
      t.string :booking_number, null: false
      
      # References
      t.references :user, null: false, foreign_key: true
      t.references :court, null: false, foreign_key: true
      t.references :venue, null: false, foreign_key: true # Denormalized
      
      # Time slot
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.integer :duration_minutes, null: false
      
      # Status
      t.string :status, null: false, default: 'confirmed'
      
      # Payment
      t.decimal :total_amount, precision: 10, scale: 2, default: 0
      t.string :payment_method
      t.string :payment_status, default: 'pending'
      t.decimal :paid_amount, precision: 10, scale: 2, default: 0
      
      # Notes
      t.text :notes
      
      # Cancellation
      t.datetime :cancelled_at
      t.references :cancelled_by, foreign_key: { to_table: :users }
      t.text :cancellation_reason
      
      # Check-in
      t.datetime :checked_in_at
      t.references :checked_in_by, foreign_key: { to_table: :users }
      
      # Creation tracking
      t.references :created_by, foreign_key: { to_table: :users }
      
      t.timestamps
    end
    
    # Indexes
    add_index :bookings, :booking_number, unique: true
    add_index :bookings, :user_id
    add_index :bookings, [:court_id, :start_time, :end_time]
    add_index :bookings, [:venue_id, :start_time]
    add_index :bookings, :status
    add_index :bookings, [:start_time, :end_time]
    
    # Check constraints
    add_check_constraint :bookings,
      'end_time > start_time',
      name: 'end_time_after_start_time'
      
    add_check_constraint :bookings,
      'duration_minutes > 0',
      name: 'positive_duration'
      
    add_check_constraint :bookings,
      'paid_amount >= 0',
      name: 'non_negative_paid_amount'
      
    add_check_constraint :bookings,
      'paid_amount <= total_amount',
      name: 'paid_not_exceeding_total'
  end
end
```

### Migration 2: Create Booking Logs

```ruby
class CreateBookingLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :booking_logs do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      
      t.string :action, null: false
      t.jsonb :changes
      t.string :ip_address
      t.text :user_agent
      
      t.datetime :created_at, null: false
    end
    
    # Indexes
    add_index :booking_logs, :booking_id
    add_index :booking_logs, :user_id
    add_index :booking_logs, :created_at
    add_index :booking_logs, :action
  end
end
```

---

## Models

### app/models/booking.rb

```ruby
class Booking < ApplicationRecord
  # ============================================================================
  # CONSTANTS
  # ============================================================================
  STATUSES = %w[confirmed completed cancelled no_show].freeze
  PAYMENT_METHODS = %w[cash online card].freeze
  PAYMENT_STATUSES = %w[pending paid refunded].freeze
  
  # ============================================================================
  # ASSOCIATIONS
  # ============================================================================
  belongs_to :user
  belongs_to :court
  belongs_to :venue
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :cancelled_by, class_name: 'User', optional: true
  belongs_to :checked_in_by, class_name: 'User', optional: true
  
  has_many :booking_logs, dependent: :destroy
  
  # Phase 6: Notifications
  # has_many :notifications, dependent: :destroy
  
  # ============================================================================
  # VALIDATIONS
  # ============================================================================
  validates :booking_number, presence: true, uniqueness: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :payment_method, inclusion: { in: PAYMENT_METHODS, allow_blank: true }
  validates :payment_status, inclusion: { in: PAYMENT_STATUSES }
  
  validate :end_time_after_start_time
  validate :no_overlapping_bookings
  validate :duration_matches_time_difference
  validate :within_operating_hours
  validate :respects_slot_durations
  
  # ============================================================================
  # CALLBACKS
  # ============================================================================
  before_validation :set_venue, if: -> { court.present? && venue.blank? }
  before_validation :calculate_duration, if: -> { start_time.present? && end_time.present? }
  before_validation :calculate_total_amount, if: :new_record?
  before_validation :generate_booking_number, if: :new_record?
  
  after_create :log_creation
  after_update :log_update
  
  # ============================================================================
  # SCOPES
  # ============================================================================
  scope :confirmed, -> { where(status: 'confirmed') }
  scope :completed, -> { where(status: 'completed') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :no_show, -> { where(status: 'no_show') }
  scope :active, -> { where(status: %w[confirmed completed]) }
  
  scope :upcoming, -> { confirmed.where('start_time > ?', Time.current).order(:start_time) }
  scope :past, -> { where('end_time < ?', Time.current).order(start_time: :desc) }
  scope :today, -> { where('DATE(start_time) = ?', Date.current) }
  scope :on_date, ->(date) { where('DATE(start_time) = ?', date) }
  
  scope :paid, -> { where(payment_status: 'paid') }
  scope :unpaid, -> { where(payment_status: 'pending') }
  
  # ============================================================================
  # CLASS METHODS
  # ============================================================================
  
  # Check if a time slot is available for booking
  def self.slot_available?(court, start_time, end_time, exclude_booking_id: nil)
    query = where(court: court)
            .confirmed
            .where.not(id: exclude_booking_id)
            .where('start_time < ? AND end_time > ?', end_time, start_time)
    
    query.empty?
  end
  
  # ============================================================================
  # INSTANCE METHODS
  # ============================================================================
  
  def confirm!
    update!(status: 'confirmed')
  end
  
  def complete!
    update!(status: 'completed')
  end
  
  def cancel!(reason: nil, cancelled_by: nil)
    update!(
      status: 'cancelled',
      cancelled_at: Time.current,
      cancelled_by: cancelled_by,
      cancellation_reason: reason
    )
  end
  
  def mark_no_show!
    update!(status: 'no_show')
  end
  
  def check_in!(checked_in_by:)
    update!(
      checked_in_at: Time.current,
      checked_in_by: checked_in_by
    )
  end
  
  def mark_paid!(amount: nil, method: 'cash')
    update!(
      payment_status: 'paid',
      paid_amount: amount || total_amount,
      payment_method: method
    )
  end
  
  def confirmed?
    status == 'confirmed'
  end
  
  def completed?
    status == 'completed'
  end
  
  def cancelled?
    status == 'cancelled'
  end
  
  def paid?
    payment_status == 'paid'
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
    start_time.strftime('%B %d, %Y')
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
    
    # Calculate based on duration and pricing rules
    hours = duration_hours
    price_per_hour = PricingRule.price_for(court.court_type, start_time)
    self.total_amount = (price_per_hour * hours).round(2)
  end
  
  def generate_booking_number
    # Format: BK-YYYYMMDD-XXXX
    date_str = Time.current.strftime('%Y%m%d')
    last_booking = Booking.where('booking_number LIKE ?', "BK-#{date_str}-%").order(:booking_number).last
    
    if last_booking
      last_sequence = last_booking.booking_number.split('-').last.to_i
      sequence = last_sequence + 1
    else
      sequence = 1
    end
    
    self.booking_number = "BK-#{date_str}-#{sequence.to_s.rjust(4, '0')}"
  end
  
  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?
    
    if end_time <= start_time
      errors.add(:end_time, 'must be after start time')
    end
  end
  
  def no_overlapping_bookings
    return if court.blank? || start_time.blank? || end_time.blank?
    
    unless Booking.slot_available?(court, start_time, end_time, exclude_booking_id: id)
      errors.add(:base, 'This time slot is already booked')
    end
  end
  
  def duration_matches_time_difference
    return if start_time.blank? || end_time.blank? || duration_minutes.blank?
    
    calculated_duration = ((end_time - start_time) / 60).to_i
    if duration_minutes != calculated_duration
      errors.add(:duration_minutes, 'does not match time slot duration')
    end
  end
  
  def within_operating_hours
    return if start_time.blank? || venue.blank?
    
    day_of_week = start_time.wday
    operating_hours = venue.venue_operating_hours.find_by(day_of_week: day_of_week)
    
    if operating_hours.nil? || operating_hours.is_closed?
      errors.add(:base, 'Venue is closed on this day')
      return
    end
    
    # Compare times
    start_time_of_day = start_time.strftime('%H:%M:%S')
    end_time_of_day = end_time.strftime('%H:%M:%S')
    opens_at = operating_hours.opens_at.strftime('%H:%M:%S')
    closes_at = operating_hours.closes_at.strftime('%H:%M:%S')
    
    if start_time_of_day < opens_at || end_time_of_day > closes_at
      errors.add(:base, "Booking must be within operating hours (#{operating_hours.formatted_hours})")
    end
  end
  
  def respects_slot_durations
    return if duration_minutes.blank? || venue.blank?
    
    settings = venue.venue_setting
    return if settings.blank?
    
    if duration_minutes < settings.minimum_slot_duration
      errors.add(:duration_minutes, "must be at least #{settings.minimum_slot_duration} minutes")
    end
    
    if duration_minutes > settings.maximum_slot_duration
      errors.add(:duration_minutes, "cannot exceed #{settings.maximum_slot_duration} minutes")
    end
  end
  
  def log_creation
    booking_logs.create!(
      user: created_by || user,
      action: 'created'
    )
  end
  
  def log_update
    return unless saved_changes.any?
    
    booking_logs.create!(
      user: Current.user, # Assumes you have Current.user set in controller
      action: 'updated',
      changes: saved_changes
    )
  end
end
```

### app/models/booking_log.rb

```ruby
class BookingLog < ApplicationRecord
  # ============================================================================
  # ASSOCIATIONS
  # ============================================================================
  belongs_to :booking
  belongs_to :user, optional: true
  
  # ============================================================================
  # VALIDATIONS
  # ============================================================================
  validates :action, presence: true
  
  # ============================================================================
  # SCOPES
  # ============================================================================
  scope :recent_first, -> { order(created_at: :desc) }
  scope :for_action, ->(action) { where(action: action) }
  
  # ============================================================================
  # INSTANCE METHODS
  # ============================================================================
  
  def user_name
    user&.full_name || 'System'
  end
  
  # Format changes for human-readable display
  def formatted_changes
    return {} if changes.blank?
    
    formatted = {}
    changes.each do |field, (old_value, new_value)|
      formatted[humanize_field(field)] = {
        from: humanize_value(field, old_value),
        to: humanize_value(field, new_value)
      }
    end
    formatted
  end
  
  def description
    case action
    when 'created'
      "#{user_name} created this booking"
    when 'updated'
      changes_text = formatted_changes.map { |field, vals| "#{field}: #{vals[:from]} → #{vals[:to]}" }.join(', ')
      "#{user_name} updated: #{changes_text}"
    when 'cancelled'
      reason = changes.dig('cancellation_reason', 1)
      "#{user_name} cancelled#{reason.present? ? " (#{reason})" : ''}"
    when 'checked_in'
      "#{user_name} checked in the customer"
    when 'completed'
      "#{user_name} marked as completed"
    else
      "#{user_name} performed #{action}"
    end
  end
  
  private
  
  def humanize_field(field)
    field.to_s.titleize
  end
  
  def humanize_value(field, value)
    case field
    when 'start_time', 'end_time'
      value.present? ? Time.parse(value.to_s).strftime('%I:%M %p, %b %d') : 'N/A'
    when 'court_id'
      Court.find_by(id: value)&.name || value
    when 'status'
      value.to_s.titleize
    else
      value.to_s
    end
  end
end
```

---

## Seed Data

**File**: `db/seeds/05_bookings.rb`

```ruby
puts "🌱 Seeding Phase 5: Bookings..."

venue = Venue.first
court = Court.first
customers = User.where.not(email: ['admin@bookturf.com', 'owner@example.com', 'receptionist@example.com'])

unless venue && court && customers.any?
  puts "  ⚠️  Missing required data. Run previous phase seeds first."
  exit
end

# Create bookings for today
today = Date.current
[9, 11, 14, 16, 19].each_with_index do |hour, index|
  customer = customers[index % customers.count]
  start_time = today.in_time_zone.change(hour: hour)
  end_time = start_time + 1.hour
  
  booking = Booking.create!(
    user: customer,
    court: court,
    venue: venue,
    start_time: start_time,
    end_time: end_time,
    status: 'confirmed',
    payment_method: 'cash',
    payment_status: 'pending',
    created_by: customer,
    notes: "Created via seed data"
  )
  
  puts "  ✅ Created booking: #{booking.booking_number} (#{booking.formatted_time_slot})"
end

# Create a past completed booking
yesterday = Date.yesterday
past_booking = Booking.create!(
  user: customers.first,
  court: court,
  venue: venue,
  start_time: yesterday.in_time_zone.change(hour: 18),
  end_time: yesterday.in_time_zone.change(hour: 19),
  status: 'completed',
  payment_method: 'cash',
  payment_status: 'paid',
  created_by: customers.first
)
past_booking.mark_paid!
puts "  ✅ Created past booking: #{past_booking.booking_number}"

# Create a cancelled booking
cancelled_booking = Booking.create!(
  user: customers.last,
  court: court,
  venue: venue,
  start_time: today.in_time_zone.change(hour: 21),
  end_time: today.in_time_zone.change(hour: 22),
  status: 'confirmed',
  created_by: customers.last
)
cancelled_booking.cancel!(reason: 'Personal emergency', cancelled_by: customers.last)
puts "  ✅ Created cancelled booking: #{cancelled_booking.booking_number}"

puts "\n✅ Phase 5 seeding complete!"
puts "  📅 Total bookings: #{Booking.count}"
puts "  ✅ Confirmed: #{Booking.confirmed.count}"
puts "  ✔️  Completed: #{Booking.completed.count}"
puts "  ❌ Cancelled: #{Booking.cancelled.count}"
puts "  📝 Booking logs: #{BookingLog.count}"
```

---

## Service Object (Optional but Recommended)

**File**: `app/services/booking_service.rb`

```ruby
class BookingService
  def initialize(user:, court:, start_time:, end_time:, **options)
    @user = user
    @court = court
    @start_time = start_time
    @end_time = end_time
    @options = options
  end
  
  def create_booking
    booking = Booking.new(
      user: @user,
      court: @court,
      start_time: @start_time,
      end_time: @end_time,
      created_by: @options[:created_by] || @user,
      notes: @options[:notes]
    )
    
    if booking.save
      # Phase 6: Send notification
      { success: true, booking: booking }
    else
      { success: false, errors: booking.errors.full_messages }
    end
  end
  
  def available_slots(date)
    # Implementation in Phase 6
  end
end
```

---

## Checklist

Before moving to Phase 6, ensure:

- [ ] Bookings migration run successfully
- [ ] Booking logs migration run successfully
- [ ] Can create bookings
- [ ] Booking number auto-generated correctly
- [ ] Double-booking prevented (validation + DB)
- [ ] Duration calculated automatically
- [ ] Total amount calculated from pricing rules
- [ ] Operating hours validation working
- [ ] Min/max slot duration validation working
- [ ] Can mark booking as paid/completed/cancelled
- [ ] Booking logs created on create/update
- [ ] Query methods working (upcoming, past, today)
- [ ] Tests passing

---

## Next Phase

Once Phase 5 is complete, proceed to:
👉 **[Phase 6: Closures & Notifications](DB_PHASE_6_CLOSURES_NOTIFICATIONS.md)**

---

*Last Updated: 2026-04-07*
