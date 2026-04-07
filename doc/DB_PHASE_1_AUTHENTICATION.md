# Database Implementation - Phase 1: Authentication & User Management

**Phase**: 1 of 6  
**Status**: Foundation  
**Dependencies**: None (Start here)  
**Estimated Time**: 1-2 days

---

## Overview

This phase sets up the core user authentication system. This is the foundation of the entire application - all other features depend on having users who can log in and be identified.

**What you'll build:**
- User registration and login
- Password encryption
- User profile management
- Global admin functionality
- Emergency contact information

---

## Tables in This Phase

### 1. users

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | bigint | PK, auto | Primary key |
| email | string | unique, not null, indexed | Login identifier |
| encrypted_password | string | not null | Bcrypt hashed password |
| first_name | string | not null | Required |
| last_name | string | not null | Required |
| phone_number | string | indexed | Optional |
| emergency_contact_name | string | nullable | For safety |
| emergency_contact_phone | string | nullable | For safety |
| is_global_admin | boolean | default: false | Developer access |
| is_active | boolean | default: true | Account status |
| created_at | datetime | not null | Auto-generated |
| updated_at | datetime | not null | Auto-generated |

---

## Rails Migration

```ruby
class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      # Authentication
      t.string :email, null: false
      t.string :encrypted_password, null: false
      
      # Profile
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :phone_number
      
      # Emergency Contact
      t.string :emergency_contact_name
      t.string :emergency_contact_phone
      
      # Flags
      t.boolean :is_global_admin, default: false, null: false
      t.boolean :is_active, default: true, null: false
      
      t.timestamps
    end
    
    # Indexes
    add_index :users, :email, unique: true
    add_index :users, :phone_number
    add_index :users, :is_global_admin
  end
end
```

---

## Model: User

**File**: `app/models/user.rb`

```ruby
class User < ApplicationRecord
  # Include default devise modules or use has_secure_password
  has_secure_password
  
  # ============================================================================
  # ASSOCIATIONS
  # ============================================================================
  # Phase 2: Venue ownership
  # has_one :venue, foreign_key: 'owner_id', dependent: :restrict_with_error
  
  # Phase 4: Roles
  # has_many :user_roles, dependent: :destroy
  # has_many :roles, through: :user_roles
  
  # Phase 5: Bookings
  # has_many :bookings, dependent: :restrict_with_error
  # has_many :created_bookings, class_name: 'Booking', foreign_key: 'created_by'
  
  # ============================================================================
  # VALIDATIONS
  # ============================================================================
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :last_name, presence: true, length: { minimum: 2, maximum: 50 }
  validates :phone_number, format: { with: /\A\+?[0-9\s\-()]+\z/, allow_blank: true }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || password.present? }
  
  # ============================================================================
  # CALLBACKS
  # ============================================================================
  before_save :normalize_email
  
  # ============================================================================
  # SCOPES
  # ============================================================================
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :global_admins, -> { where(is_global_admin: true) }
  scope :customers, -> { where(is_global_admin: false) }
  
  # ============================================================================
  # INSTANCE METHODS
  # ============================================================================
  
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def initials
    "#{first_name[0]}#{last_name[0]}".upcase
  end
  
  def activate!
    update(is_active: true)
  end
  
  def deactivate!
    update(is_active: false)
  end
  
  def global_admin?
    is_global_admin
  end
  
  private
  
  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
```

---

## Seed Data

**File**: `db/seeds/01_users.rb`

```ruby
puts "🌱 Seeding Phase 1: Users..."

# Create a global admin (developer account)
global_admin = User.find_or_create_by!(email: 'admin@bookturf.com') do |user|
  user.first_name = 'Global'
  user.last_name = 'Admin'
  user.password = 'password123' # Change in production!
  user.phone_number = '+92 300 1234567'
  user.is_global_admin = true
  user.is_active = true
end

puts "  ✅ Created global admin: #{global_admin.email}"

# Create a test venue owner
owner = User.find_or_create_by!(email: 'owner@example.com') do |user|
  user.first_name = 'Ahmed'
  user.last_name = 'Khan'
  user.password = 'password123'
  user.phone_number = '+92 321 9876543'
  user.emergency_contact_name = 'Fatima Khan'
  user.emergency_contact_phone = '+92 333 1112222'
  user.is_active = true
end

puts "  ✅ Created venue owner: #{owner.email}"

# Create test customers
customers = [
  { first_name: 'Ali', last_name: 'Hassan', email: 'ali@example.com' },
  { first_name: 'Sara', last_name: 'Ahmed', email: 'sara@example.com' },
  { first_name: 'Omar', last_name: 'Malik', email: 'omar@example.com' }
]

customers.each do |customer_data|
  customer = User.find_or_create_by!(email: customer_data[:email]) do |user|
    user.first_name = customer_data[:first_name]
    user.last_name = customer_data[:last_name]
    user.password = 'password123'
    user.phone_number = "+92 #{rand(300..345)} #{rand(1000000..9999999)}"
    user.is_active = true
  end
  
  puts "  ✅ Created customer: #{customer.email}"
end

puts "✅ Phase 1 seeding complete! Created #{User.count} users."
```

---

## Testing

**File**: `spec/models/user_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'requires email' do
      user = User.new(email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end
    
    it 'requires unique email' do
      User.create!(
        email: 'test@example.com',
        password: 'password123',
        first_name: 'Test',
        last_name: 'User'
      )
      
      duplicate = User.new(
        email: 'test@example.com',
        password: 'password123',
        first_name: 'Another',
        last_name: 'User'
      )
      
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include('has already been taken')
    end
    
    it 'requires valid email format' do
      user = User.new(email: 'invalid-email')
      expect(user).not_to be_valid
    end
    
    it 'requires password with minimum length' do
      user = User.new(password: 'short')
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('is too short (minimum is 8 characters)')
    end
    
    it 'requires first name' do
      user = User.new(first_name: nil)
      expect(user).not_to be_valid
    end
    
    it 'requires last name' do
      user = User.new(last_name: nil)
      expect(user).not_to be_valid
    end
    
    it 'validates phone number format' do
      user = User.new(phone_number: 'abc123')
      expect(user).not_to be_valid
    end
  end
  
  describe 'scopes' do
    it 'returns active users' do
      active_user = User.create!(
        email: 'active@example.com',
        password: 'password123',
        first_name: 'Active',
        last_name: 'User',
        is_active: true
      )
      
      inactive_user = User.create!(
        email: 'inactive@example.com',
        password: 'password123',
        first_name: 'Inactive',
        last_name: 'User',
        is_active: false
      )
      
      expect(User.active).to include(active_user)
      expect(User.active).not_to include(inactive_user)
    end
  end
  
  describe '#full_name' do
    it 'returns first and last name combined' do
      user = User.new(first_name: 'Ahmed', last_name: 'Khan')
      expect(user.full_name).to eq('Ahmed Khan')
    end
  end
  
  describe '#global_admin?' do
    it 'returns true for global admins' do
      admin = User.new(is_global_admin: true)
      expect(admin.global_admin?).to be true
    end
    
    it 'returns false for regular users' do
      user = User.new(is_global_admin: false)
      expect(user.global_admin?).to be false
    end
  end
end
```

---

## API Endpoints (Optional)

If building API alongside:

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    # Authentication
    post 'auth/signup', to: 'auth#signup'
    post 'auth/login', to: 'auth#login'
    delete 'auth/logout', to: 'auth#logout'
    
    # User profile
    get 'profile', to: 'users#show'
    patch 'profile', to: 'users#update'
  end
end
```

---

## Checklist

Before moving to Phase 2, ensure:

- [ ] Migration created and run successfully (`rails db:migrate`)
- [ ] User model created with all validations
- [ ] Seed data runs without errors (`rails db:seed`)
- [ ] Can create users via Rails console
- [ ] Email uniqueness enforced
- [ ] Password encryption working
- [ ] Tests passing (if using TDD)
- [ ] Can authenticate users (login/logout)
- [ ] Active/inactive status working
- [ ] Global admin flag functional

---

## Common Issues & Solutions

**Issue**: Email not unique (case sensitivity)
- **Solution**: Use `uniqueness: { case_sensitive: false }` and normalize email before save

**Issue**: Password not encrypting
- **Solution**: Ensure `has_secure_password` included or Devise configured properly

**Issue**: Can't delete user (foreign key constraint)
- **Solution**: Expected! Will be resolved when associations added in later phases

---

## Next Phase

Once Phase 1 is complete, proceed to:
👉 **[Phase 2: Venue Setup](DB_PHASE_2_VENUES.md)**

---

*Last Updated: 2026-04-07*
