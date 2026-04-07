# Database Implementation - Phase 3: Court Management

**Phase**: 3 of 6  
**Status**: Core Features  
**Dependencies**: Phase 2 (Venues must exist)  
**Estimated Time**: 2-3 days

---

## Overview

This phase builds the court system - the actual playing areas that users will book. You'll create sport types, individual courts, and flexible pricing rules that vary by time of day.

**What you'll build:**
- Sport types (Tennis, Badminton, Basketball, etc.)
- Individual courts with names and descriptions
- Time-based pricing rules (peak/off-peak pricing)
- Court availability management

---

## Tables in This Phase

### 1. court_types (Sport types - global)
### 2. courts (Individual courts within the venue)
### 3. pricing_rules (Flexible time-based pricing per court type)

---

## Rails Migrations

### Migration 1: Create Court Types

```ruby
class CreateCourtTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :court_types do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :icon
      
      t.timestamps
    end
    
    # Indexes
    add_index :court_types, :name, unique: true
    add_index :court_types, :slug, unique: true
  end
end
```

### Migration 2: Create Courts

```ruby
class CreateCourts < ActiveRecord::Migration[7.1]
  def change
    create_table :courts do |t|
      t.references :venue, null: false, foreign_key: true
      t.references :court_type, null: false, foreign_key: true
      
      t.string :name, null: false
      t.text :description
      t.boolean :is_active, default: true, null: false
      t.integer :display_order, default: 0, null: false
      
      t.timestamps
    end
    
    # Indexes
    add_index :courts, [:venue_id, :name], unique: true
    add_index :courts, :court_type_id
    add_index :courts, :is_active
  end
end
```

### Migration 3: Create Pricing Rules

```ruby
class CreatePricingRules < ActiveRecord::Migration[7.1]
  def change
    create_table :pricing_rules do |t|
      t.references :venue, null: false, foreign_key: true
      t.references :court_type, null: false, foreign_key: true
      
      t.string :name, null: false
      t.decimal :price_per_hour, precision: 10, scale: 2, null: false
      
      # Time-based rules (nullable for "all day" rules)
      t.integer :day_of_week  # 0-6, null = all days
      t.time :start_time
      t.time :end_time
      
      # Date-based rules (nullable for permanent rules)
      t.date :start_date
      t.date :end_date
      
      # Priority and status
      t.integer :priority, default: 0, null: false
      t.boolean :is_active, default: true, null: false
      
      t.timestamps
    end
    
    # Indexes
    add_index :pricing_rules, [:venue_id, :court_type_id]
    add_index :pricing_rules, :is_active
    add_index :pricing_rules, :priority
    
    # Check constraints
    add_check_constraint :pricing_rules,
      'price_per_hour >= 0',
      name: 'price_non_negative'
  end
end
```

---

## Models

### app/models/court_type.rb

```ruby
class CourtType < ApplicationRecord
  # ============================================================================
  # ASSOCIATIONS
  # ============================================================================
  has_many :courts, dependent: :restrict_with_error
  has_many :pricing_rules, dependent: :destroy
  
  # ============================================================================
  # VALIDATIONS
  # ============================================================================
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :slug, format: { with: /\A[a-z0-9\-]+\z/, message: 'only lowercase letters, numbers, and hyphens' }
  
  # ============================================================================
  # CALLBACKS
  # ============================================================================
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  
  # ============================================================================
  # SCOPES
  # ============================================================================
  scope :alphabetical, -> { order(:name) }
  
  # ============================================================================
  # INSTANCE METHODS
  # ============================================================================
  
  def to_param
    slug
  end
  
  private
  
  def generate_slug
    self.slug = name.parameterize
  end
end
```

### app/models/court.rb

```ruby
class Court < ApplicationRecord
  # ============================================================================
  # ASSOCIATIONS
  # ============================================================================
  belongs_to :venue
  belongs_to :court_type
  
  # Phase 5: Bookings
  # has_many :bookings, dependent: :restrict_with_error
  
  # Phase 6: Court closures
  # has_many :court_closures, dependent: :destroy
  
  # ============================================================================
  # VALIDATIONS
  # ============================================================================
  validates :name, presence: true
  validates :name, uniqueness: { scope: :venue_id }
  
  # ============================================================================
  # CALLBACKS
  # ============================================================================
  # None needed
  
  # ============================================================================
  # SCOPES
  # ============================================================================
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :by_display_order, -> { order(:display_order, :name) }
  scope :of_type, ->(court_type) { where(court_type: court_type) }
  
  # ============================================================================
  # INSTANCE METHODS
  # ============================================================================
  
  def sport_name
    court_type.name
  end
  
  def full_name
    "#{name} (#{sport_name})"
  end
  
  def activate!
    update(is_active: true)
  end
  
  def deactivate!
    update(is_active: false)
  end
  
  # Check if court is available at a specific time
  # (Will be enhanced in Phase 5 with booking checks)
  def available_at?(start_time, end_time)
    return false unless is_active?
    # Phase 5: Add booking overlap check
    # Phase 6: Add court closure check
    true
  end
end
```

### app/models/pricing_rule.rb

```ruby
class PricingRule < ApplicationRecord
  # ============================================================================
  # ASSOCIATIONS
  # ============================================================================
  belongs_to :venue
  belongs_to :court_type
  
  # ============================================================================
  # VALIDATIONS
  # ============================================================================
  validates :name, presence: true
  validates :price_per_hour, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :day_of_week, inclusion: { in: 0..6, allow_nil: true }
  validates :priority, presence: true, numericality: { only_integer: true }
  
  validate :end_time_after_start_time
  validate :end_date_after_start_date
  
  # ============================================================================
  # SCOPES
  # ============================================================================
  scope :active, -> { where(is_active: true) }
  scope :for_court_type, ->(court_type) { where(court_type: court_type) }
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
      datetime.strftime('%H:%M:%S'),
      datetime.strftime('%H:%M:%S'),
      datetime.to_date,
      datetime.to_date
    )
  end
  
  # ============================================================================
  # CLASS METHODS
  # ============================================================================
  
  # Find the applicable price for a given court type at a specific time
  def self.price_for(court_type, datetime)
    rule = for_court_type(court_type)
           .applicable_at(datetime)
           .by_priority
           .first
    
    rule&.price_per_hour || 0
  end
  
  # ============================================================================
  # INSTANCE METHODS
  # ============================================================================
  
  def applies_to?(datetime)
    return false unless is_active?
    
    # Check day of week
    return false if day_of_week.present? && datetime.wday != day_of_week
    
    # Check time range
    if start_time.present? && end_time.present?
      time_of_day = datetime.strftime('%H:%M:%S')
      return false if time_of_day < start_time.strftime('%H:%M:%S')
      return false if time_of_day >= end_time.strftime('%H:%M:%S')
    end
    
    # Check date range
    return false if start_date.present? && datetime.to_date < start_date
    return false if end_date.present? && datetime.to_date > end_date
    
    true
  end
  
  def time_range
    return 'All day' if start_time.blank? || end_time.blank?
    "#{start_time.strftime('%I:%M %p')} - #{end_time.strftime('%I:%M %p')}"
  end
  
  def day_name
    return 'All days' if day_of_week.blank?
    Date::DAYNAMES[day_of_week]
  end
  
  private
  
  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?
    
    if end_time <= start_time
      errors.add(:end_time, 'must be after start time')
    end
  end
  
  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?
    
    if end_date < start_date
      errors.add(:end_date, 'must be after start date')
    end
  end
end
```

---

## Seed Data

**File**: `db/seeds/03_courts.rb`

```ruby
puts "🌱 Seeding Phase 3: Court Types and Courts..."

# ============================================================
# COURT TYPES (Sports)
# ============================================================
court_types_data = [
  { name: 'Badminton', slug: 'badminton', icon: '🏸' },
  { name: 'Tennis', slug: 'tennis', icon: '🎾' },
  { name: 'Basketball', slug: 'basketball', icon: '🏀' },
  { name: 'Squash', slug: 'squash', icon: '🎾' },
  { name: 'Volleyball', slug: 'volleyball', icon: '🏐' },
  { name: 'Futsal', slug: 'futsal', icon: '⚽' },
  { name: 'Table Tennis', slug: 'table-tennis', icon: '🏓' }
]

court_types = {}
court_types_data.each do |data|
  court_type = CourtType.find_or_create_by!(slug: data[:slug]) do |ct|
    ct.name = data[:name]
    ct.icon = data[:icon]
    ct.description = "#{data[:name]} court"
  end
  court_types[data[:slug]] = court_type
  puts "  ✅ Created court type: #{court_type.name}"
end

# ============================================================
# COURTS
# ============================================================
venue = Venue.first

unless venue
  puts "  ⚠️  No venue found. Run Phase 2 seeds first."
  exit
end

courts_data = [
  { name: 'Badminton Court 1', type: 'badminton', order: 1 },
  { name: 'Badminton Court 2', type: 'badminton', order: 2 },
  { name: 'Badminton Court 3', type: 'badminton', order: 3 },
  { name: 'Tennis Court 1', type: 'tennis', order: 4 },
  { name: 'Tennis Court 2', type: 'tennis', order: 5 },
  { name: 'Basketball Court', type: 'basketball', order: 6 }
]

courts_data.each do |data|
  court = Court.find_or_create_by!(venue: venue, name: data[:name]) do |c|
    c.court_type = court_types[data[:type]]
    c.display_order = data[:order]
    c.is_active = true
    c.description = "Premium #{court_types[data[:type]].name} court with professional flooring"
  end
  puts "  ✅ Created court: #{court.full_name}"
end

# ============================================================
# PRICING RULES
# ============================================================

# Badminton Pricing
badminton = court_types['badminton']

# Weekday Morning (Mon-Fri, 6 AM - 12 PM): 1500 PKR/hour
PricingRule.find_or_create_by!(
  venue: venue,
  court_type: badminton,
  name: 'Weekday Morning'
) do |pr|
  pr.price_per_hour = 1500
  pr.start_time = '06:00'
  pr.end_time = '12:00'
  pr.priority = 1
  pr.is_active = true
end

# Weekday Afternoon (Mon-Fri, 12 PM - 6 PM): 1200 PKR/hour
PricingRule.find_or_create_by!(
  venue: venue,
  court_type: badminton,
  name: 'Weekday Afternoon'
) do |pr|
  pr.price_per_hour = 1200
  pr.start_time = '12:00'
  pr.end_time = '18:00'
  pr.priority = 1
  pr.is_active = true
end

# Weekday Evening - PEAK (Mon-Fri, 6 PM - 11 PM): 2500 PKR/hour
PricingRule.find_or_create_by!(
  venue: venue,
  court_type: badminton,
  name: 'Weekday Evening (Peak)'
) do |pr|
  pr.price_per_hour = 2500
  pr.start_time = '18:00'
  pr.end_time = '23:00'
  pr.priority = 2  # Higher priority for peak time
  pr.is_active = true
end

# Weekend (Sat-Sun, All Day): 2000 PKR/hour
[0, 6].each do |day|  # 0 = Sunday, 6 = Saturday
  day_name = Date::DAYNAMES[day]
  PricingRule.find_or_create_by!(
    venue: venue,
    court_type: badminton,
    name: "#{day_name} All Day",
    day_of_week: day
  ) do |pr|
    pr.price_per_hour = 2000
    pr.priority = 1
    pr.is_active = true
  end
end

puts "  ✅ Created pricing rules for Badminton"

# Tennis Pricing (Higher rates)
tennis = court_types['tennis']

PricingRule.find_or_create_by!(
  venue: venue,
  court_type: tennis,
  name: 'Standard Rate'
) do |pr|
  pr.price_per_hour = 3000
  pr.priority = 0
  pr.is_active = true
end

puts "  ✅ Created pricing rules for Tennis"

# Basketball Pricing
basketball = court_types['basketball']

PricingRule.find_or_create_by!(
  venue: venue,
  court_type: basketball,
  name: 'Standard Rate'
) do |pr|
  pr.price_per_hour = 2500
  pr.priority = 0
  pr.is_active = true
end

puts "  ✅ Created pricing rules for Basketball"

puts "\n✅ Phase 3 seeding complete!"
puts "  📊 Court Types: #{CourtType.count}"
puts "  🏟️  Courts: #{Court.count}"
puts "  💰 Pricing Rules: #{PricingRule.count}"
```

---

## Testing

**File**: `spec/models/court_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe Court, type: :model do
  let(:venue) { create(:venue) }
  let(:court_type) { create(:court_type, name: 'Badminton') }
  
  describe 'validations' do
    it 'requires name' do
      court = Court.new(name: nil, venue: venue, court_type: court_type)
      expect(court).not_to be_valid
    end
    
    it 'requires unique name within venue' do
      Court.create!(name: 'Court 1', venue: venue, court_type: court_type)
      duplicate = Court.new(name: 'Court 1', venue: venue, court_type: court_type)
      expect(duplicate).not_to be_valid
    end
    
    it 'allows same name in different venues' do
      other_venue = create(:venue, name: 'Other Venue')
      Court.create!(name: 'Court 1', venue: venue, court_type: court_type)
      other_court = Court.new(name: 'Court 1', venue: other_venue, court_type: court_type)
      expect(other_court).to be_valid
    end
  end
  
  describe '#full_name' do
    it 'returns name with sport type' do
      court = Court.new(name: 'Court 1', court_type: court_type)
      expect(court.full_name).to eq('Court 1 (Badminton)')
    end
  end
end
```

**File**: `spec/models/pricing_rule_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe PricingRule, type: :model do
  let(:venue) { create(:venue) }
  let(:court_type) { create(:court_type) }
  
  describe '.price_for' do
    it 'returns price for applicable rule' do
      rule = PricingRule.create!(
        venue: venue,
        court_type: court_type,
        name: 'Evening Peak',
        price_per_hour: 2500,
        start_time: '18:00',
        end_time: '23:00',
        priority: 2
      )
      
      # Friday 7 PM
      datetime = Time.zone.parse('2026-04-17 19:00')
      price = PricingRule.price_for(court_type, datetime)
      
      expect(price).to eq(2500)
    end
    
    it 'returns highest priority rule when multiple match' do
      # Low priority rule
      PricingRule.create!(
        venue: venue,
        court_type: court_type,
        name: 'Standard',
        price_per_hour: 1500,
        priority: 1
      )
      
      # High priority rule for evenings
      PricingRule.create!(
        venue: venue,
        court_type: court_type,
        name: 'Peak',
        price_per_hour: 2500,
        start_time: '18:00',
        end_time: '23:00',
        priority: 2
      )
      
      datetime = Time.zone.parse('2026-04-17 19:00')
      price = PricingRule.price_for(court_type, datetime)
      
      expect(price).to eq(2500)  # Should use higher priority
    end
  end
end
```

---

## Checklist

Before moving to Phase 4, ensure:

- [ ] All three migrations run successfully
- [ ] Court types seeded (Badminton, Tennis, Basketball, etc.)
- [ ] Courts created and linked to venue
- [ ] Courts have unique names within venue
- [ ] Pricing rules created with time-based logic
- [ ] Can query price for specific court type and time
- [ ] Priority system works for overlapping rules
- [ ] Active/inactive status works for courts
- [ ] Display order works for court sorting
- [ ] Tests passing

---

## Next Phase

Once Phase 3 is complete, proceed to:
👉 **[Phase 4: Roles & Permissions](DB_PHASE_4_ROLES.md)**

---

*Last Updated: 2026-04-07*
