# Database Implementation - Phase 2: Venue Setup

**Phase**: 2 of 6  
**Status**: Core Infrastructure  
**Dependencies**: Phase 1 (Users must exist)  
**Estimated Time**: 2-3 days

---

## Overview

This phase creates the venue infrastructure - the central entity that owns courts, bookings, and settings. You'll build the venue profile, its configuration settings, and operating hours schedule.

**What you'll build:**
- Venue registration and profile
- Venue configuration (timezone, currency, slot durations)
- Operating hours (different times for each day of week)
- Google Maps integration via coordinates

---

## Tables in This Phase

### 1. venues
### 2. venue_settings (1:1 with venues)
### 3. venue_operating_hours (1:many with venues - 7 records per venue)

---

## Rails Migrations

### Migration 1: Create Venues

```ruby
class CreateVenues < ActiveRecord::Migration[7.1]
  def change
    create_table :venues do |t|
      # Ownership
      t.references :owner, null: false, foreign_key: { to_table: :users }
      
      # Identity
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      
      # Location
      t.text :address, null: false
      t.string :city
      t.string :state
      t.string :country
      t.string :postal_code
      t.decimal :latitude, precision: 10, scale: 8
      t.decimal :longitude, precision: 11, scale: 8
      
      # Contact
      t.string :phone_number
      t.string :email
      
      # Status
      t.boolean :is_active, default: true, null: false
      
      t.timestamps
    end
    
    # Indexes
    add_index :venues, :owner_id
    add_index :venues, :slug, unique: true
    add_index :venues, :city
    add_index :venues, :state
    add_index :venues, :country
    add_index :venues, :is_active
  end
end
```

### Migration 2: Create Venue Settings

```ruby
class CreateVenueSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :venue_settings do |t|
      t.references :venue, null: false, foreign_key: true, index: { unique: true }
      
      # Slot Configuration
      t.integer :minimum_slot_duration, null: false, default: 60
      t.integer :maximum_slot_duration, null: false, default: 180
      t.integer :slot_interval, null: false, default: 30
      
      # Booking Rules
      t.integer :advance_booking_days, default: 30
      t.boolean :requires_approval, default: false, null: false
      t.integer :cancellation_hours
      
      # Localization
      t.string :timezone, null: false, default: 'Asia/Karachi'
      t.string :currency, default: 'PKR'
      
      t.timestamps
    end
    
    # Check constraints
    add_check_constraint :venue_settings, 
      'minimum_slot_duration > 0', 
      name: 'minimum_slot_duration_positive'
      
    add_check_constraint :venue_settings, 
      'maximum_slot_duration >= minimum_slot_duration', 
      name: 'maximum_greater_than_minimum'
      
    add_check_constraint :venue_settings, 
      'slot_interval > 0', 
      name: 'slot_interval_positive'
  end
end
```

### Migration 3: Create Venue Operating Hours

```ruby
class CreateVenueOperatingHours < ActiveRecord::Migration[7.1]
  def change
    create_table :venue_operating_hours do |t|
      t.references :venue, null: false, foreign_key: true
      
      t.integer :day_of_week, null: false # 0=Sunday, 6=Saturday
      t.time :opens_at, null: false
      t.time :closes_at, null: false
      t.boolean :is_closed, default: false, null: false
      
      t.timestamps
    end
    
    # Indexes
    add_index :venue_operating_hours, [:venue_id, :day_of_week], unique: true
    
    # Check constraints
    add_check_constraint :venue_operating_hours,
      'day_of_week BETWEEN 0 AND 6',
      name: 'valid_day_of_week'
  end
end
```

---

## Models

### app/models/venue.rb

```ruby
class Venue < ApplicationRecord
  # ============================================================================
  # ASSOCIATIONS
  # ============================================================================
  belongs_to :owner, class_name: 'User', foreign_key: 'owner_id'
  
  has_one :venue_setting, dependent: :destroy
  has_many :venue_operating_hours, -> { order(:day_of_week) }, dependent: :destroy
  
  # Phase 3: Courts
  # has_many :courts, dependent: :destroy
  
  # Phase 5: Bookings
  # has_many :bookings, dependent: :restrict_with_error
  
  # Phase 6: Closures & Notifications
  # has_many :court_closures, dependent: :destroy
  # has_many :notifications, dependent: :destroy
  
  # Accept nested attributes for settings and hours
  accepts_nested_attributes_for :venue_setting
  accepts_nested_attributes_for :venue_operating_hours, allow_destroy: true
  
  # ============================================================================
  # VALIDATIONS
  # ============================================================================
  validates :name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :slug, presence: true, uniqueness: true
  validates :slug, format: { with: /\A[a-z0-9\-]+\z/, message: 'only lowercase letters, numbers, and hyphens' }
  validates :address, presence: true
  validates :phone_number, format: { with: /\A\+?[0-9\s\-()]+\z/, allow_blank: true }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  
  # ============================================================================
  # CALLBACKS
  # ============================================================================
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  after_create :create_default_settings
  after_create :create_default_operating_hours
  
  # ============================================================================
  # SCOPES
  # ============================================================================
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :in_city, ->(city) { where(city: city) }
  
  # ============================================================================
  # INSTANCE METHODS
  # ============================================================================
  
  def google_maps_url
    return nil unless latitude.present? && longitude.present?
    "https://www.google.com/maps?q=#{latitude},#{longitude}"
  end
  
  def activate!
    update(is_active: true)
  end
  
  def deactivate!
    update(is_active: false)
  end
  
  def operating_hours_for(day_of_week)
    venue_operating_hours.find_by(day_of_week: day_of_week)
  end
  
  def open_on?(day_of_week)
    hours = operating_hours_for(day_of_week)
    hours.present? && !hours.is_closed
  end
  
  def to_param
    slug
  end
  
  private
  
  def generate_slug
    self.slug = name.parameterize
  end
  
  def create_default_settings
    create_venue_setting! unless venue_setting.present?
  end
  
  def create_default_operating_hours
    return if venue_operating_hours.any?
    
    # Create default hours: Monday-Sunday, 9 AM - 11 PM
    (0..6).each do |day|
      venue_operating_hours.create!(
        day_of_week: day,
        opens_at: '09:00',
        closes_at: '23:00',
        is_closed: false
      )
    end
  end
end
```

### app/models/venue_setting.rb

```ruby
class VenueSetting < ApplicationRecord
  # ============================================================================
  # ASSOCIATIONS
  # ============================================================================
  belongs_to :venue
  
  # ============================================================================
  # VALIDATIONS
  # ============================================================================
  validates :minimum_slot_duration, presence: true, numericality: { greater_than: 0 }
  validates :maximum_slot_duration, presence: true, numericality: { greater_than: 0 }
  validates :slot_interval, presence: true, numericality: { greater_than: 0 }
  validates :timezone, presence: true
  validates :currency, presence: true
  
  validate :maximum_greater_than_minimum
  
  # ============================================================================
  # INSTANCE METHODS
  # ============================================================================
  
  def slot_durations
    (minimum_slot_duration..maximum_slot_duration).step(slot_interval).to_a
  end
  
  private
  
  def maximum_greater_than_minimum
    return unless minimum_slot_duration.present? && maximum_slot_duration.present?
    
    if maximum_slot_duration < minimum_slot_duration
      errors.add(:maximum_slot_duration, 'must be greater than or equal to minimum')
    end
  end
end
```

### app/models/venue_operating_hour.rb

```ruby
class VenueOperatingHour < ApplicationRecord
  # ============================================================================
  # CONSTANTS
  # ============================================================================
  DAYS_OF_WEEK = {
    0 => 'Sunday',
    1 => 'Monday',
    2 => 'Tuesday',
    3 => 'Wednesday',
    4 => 'Thursday',
    5 => 'Friday',
    6 => 'Saturday'
  }.freeze
  
  # ============================================================================
  # ASSOCIATIONS
  # ============================================================================
  belongs_to :venue
  
  # ============================================================================
  # VALIDATIONS
  # ============================================================================
  validates :day_of_week, presence: true, inclusion: { in: 0..6 }
  validates :day_of_week, uniqueness: { scope: :venue_id }
  validates :opens_at, presence: true, unless: :is_closed?
  validates :closes_at, presence: true, unless: :is_closed?
  
  validate :closes_after_opens
  
  # ============================================================================
  # SCOPES
  # ============================================================================
  scope :open_days, -> { where(is_closed: false) }
  scope :closed_days, -> { where(is_closed: true) }
  
  # ============================================================================
  # INSTANCE METHODS
  # ============================================================================
  
  def day_name
    DAYS_OF_WEEK[day_of_week]
  end
  
  def formatted_hours
    return 'Closed' if is_closed?
    "#{opens_at.strftime('%I:%M %p')} - #{closes_at.strftime('%I:%M %p')}"
  end
  
  private
  
  def closes_after_opens
    return if is_closed? || opens_at.blank? || closes_at.blank?
    
    if closes_at <= opens_at
      errors.add(:closes_at, 'must be after opening time')
    end
  end
end
```

---

## Seed Data

**File**: `db/seeds/02_venues.rb`

```ruby
puts "🌱 Seeding Phase 2: Venues..."

owner = User.find_by(email: 'owner@example.com')

unless owner
  puts "  ⚠️  No owner found. Run Phase 1 seeds first."
  exit
end

# Create main venue
venue = Venue.find_or_create_by!(slug: 'sports-arena-karachi') do |v|
  v.owner = owner
  v.name = 'Sports Arena Karachi'
  v.description = 'Premier sports facility in Karachi with badminton, tennis, and basketball courts'
  v.address = 'Plot 123, Block 5, Clifton'
  v.city = 'Karachi'
  v.state = 'Sindh'
  v.country = 'Pakistan'
  v.postal_code = '75600'
  v.latitude = 24.8175
  v.longitude = 67.0297
  v.phone_number = '+92 21 35123456'
  v.email = 'info@sportsarena.pk'
  v.is_active = true
end

puts "  ✅ Created venue: #{venue.name}"
puts "  📍 Google Maps: #{venue.google_maps_url}"

# Settings are auto-created by callback, but we can update them
venue.venue_setting.update!(
  minimum_slot_duration: 60,
  maximum_slot_duration: 180,
  slot_interval: 30,
  advance_booking_days: 30,
  requires_approval: false,
  cancellation_hours: 24,
  timezone: 'Asia/Karachi',
  currency: 'PKR'
)

puts "  ✅ Updated venue settings"

# Operating hours are auto-created, but let's update weekend hours
weekend_days = [0, 6] # Sunday and Saturday
venue.venue_operating_hours.where(day_of_week: weekend_days).update_all(
  opens_at: '08:00',
  closes_at: '00:00' # Midnight
)

puts "  ✅ Updated operating hours (weekends open 8 AM - 12 AM)"

# Display operating hours
puts "\n  📅 Operating Hours:"
venue.venue_operating_hours.order(:day_of_week).each do |hours|
  puts "     #{hours.day_name}: #{hours.formatted_hours}"
end

puts "\n✅ Phase 2 seeding complete!"
```

---

## Testing

**File**: `spec/models/venue_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe Venue, type: :model do
  let(:owner) { User.create!(email: 'owner@test.com', password: 'password123', first_name: 'Test', last_name: 'Owner') }
  
  describe 'validations' do
    it 'requires name' do
      venue = Venue.new(name: nil, owner: owner)
      expect(venue).not_to be_valid
    end
    
    it 'requires address' do
      venue = Venue.new(name: 'Test Venue', address: nil, owner: owner)
      expect(venue).not_to be_valid
    end
    
    it 'auto-generates slug from name' do
      venue = Venue.create!(name: 'My Test Venue', address: 'Test Address', owner: owner)
      expect(venue.slug).to eq('my-test-venue')
    end
    
    it 'requires unique slug' do
      Venue.create!(name: 'Test', slug: 'test-venue', address: 'Addr', owner: owner)
      duplicate = Venue.new(name: 'Test 2', slug: 'test-venue', address: 'Addr 2', owner: owner)
      expect(duplicate).not_to be_valid
    end
  end
  
  describe 'callbacks' do
    it 'creates default settings after creation' do
      venue = Venue.create!(name: 'Test Venue', address: 'Test Address', owner: owner)
      expect(venue.venue_setting).to be_present
    end
    
    it 'creates default operating hours after creation' do
      venue = Venue.create!(name: 'Test Venue', address: 'Test Address', owner: owner)
      expect(venue.venue_operating_hours.count).to eq(7)
    end
  end
  
  describe '#google_maps_url' do
    it 'returns Google Maps URL when coordinates present' do
      venue = Venue.new(latitude: 24.8175, longitude: 67.0297)
      expect(venue.google_maps_url).to eq('https://www.google.com/maps?q=24.8175,67.0297')
    end
    
    it 'returns nil when coordinates missing' do
      venue = Venue.new
      expect(venue.google_maps_url).to be_nil
    end
  end
end
```

---

## Checklist

Before moving to Phase 3, ensure:

- [ ] All three migrations run successfully
- [ ] Venue model with validations working
- [ ] Venue settings auto-created on venue creation
- [ ] Operating hours (7 records) auto-created
- [ ] Slug auto-generated from venue name
- [ ] Google Maps URL generated from coordinates
- [ ] Can update venue settings
- [ ] Can update operating hours for specific days
- [ ] Tests passing
- [ ] Seed data creates venue with owner

---

## Next Phase

Once Phase 2 is complete, proceed to:
👉 **[Phase 3: Court Management](DB_PHASE_3_COURTS.md)**

---

*Last Updated: 2026-04-07*
