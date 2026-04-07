# Database Implementation - Phase 4: Roles & Permissions

**Phase**: 4 of 6  
**Status**: Access Control  
**Dependencies**: Phase 1 (Users)  
**Estimated Time**: 3-4 days

---

## Overview

This phase implements the role-based access control (RBAC) system. You'll create roles, permissions, and assign them to users. This determines who can do what in the system.

**What you'll build:**
- System roles (Owner, Admin, Receptionist, Staff, Customer)
- Custom roles (created by venue owners)
- Granular permissions (create:bookings, read:reports, etc.)
- Role-permission assignments
- User-role assignments

---

## Tables in This Phase

### 1. roles (System and custom roles)
### 2. permissions (Granular action-based permissions)
### 3. role_permissions (Many-to-many: roles ↔ permissions)
### 4. user_roles (Many-to-many: users ↔ roles)

---

## Rails Migrations

### Migration 1: Create Roles

```ruby
class CreateRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :roles do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.boolean :is_custom, default: false, null: false
      
      t.timestamps
    end
    
    # Indexes
    add_index :roles, :name, unique: true
    add_index :roles, :slug, unique: true
    add_index :roles, :is_custom
  end
end
```

### Migration 2: Create Permissions

```ruby
class CreatePermissions < ActiveRecord::Migration[7.1]
  def change
    create_table :permissions do |t|
      t.string :resource, null: false
      t.string :action, null: false
      t.string :name, null: false
      t.text :description
      
      t.timestamps
    end
    
    # Indexes
    add_index :permissions, :name, unique: true
    add_index :permissions, [:resource, :action], unique: true
    add_index :permissions, :resource
  end
end
```

### Migration 3: Create Role Permissions (Join Table)

```ruby
class CreateRolePermissions < ActiveRecord::Migration[7.1]
  def change
    create_table :role_permissions do |t|
      t.references :role, null: false, foreign_key: true
      t.references :permission, null: false, foreign_key: true
      
      t.timestamps
    end
    
    # Unique constraint: a role can have a permission only once
    add_index :role_permissions, [:role_id, :permission_id], unique: true
  end
end
```

### Migration 4: Create User Roles (Join Table)

```ruby
class CreateUserRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :user_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true
      t.references :assigned_by, foreign_key: { to_table: :users }
      t.datetime :assigned_at, null: false
      
      t.timestamps
    end
    
    # Unique constraint: a user can have a role only once
    add_index :user_roles, [:user_id, :role_id], unique: true
    add_index :user_roles, :role_id
  end
end
```

---

## Models

### app/models/role.rb

```ruby
class Role < ApplicationRecord
  # ============================================================================
  # CONSTANTS
  # ============================================================================
  SYSTEM_ROLES = %w[owner admin receptionist staff customer].freeze
  
  # ============================================================================
  # ASSOCIATIONS
  # ============================================================================
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions
  
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles
  
  # ============================================================================
  # VALIDATIONS
  # ============================================================================
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :slug, format: { with: /\A[a-z0-9\-_]+\z/, message: 'only lowercase letters, numbers, hyphens, and underscores' }
  
  validate :system_role_cannot_be_deleted, on: :destroy
  
  # ============================================================================
  # CALLBACKS
  # ============================================================================
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  
  # ============================================================================
  # SCOPES
  # ============================================================================
  scope :system_roles, -> { where(is_custom: false) }
  scope :custom_roles, -> { where(is_custom: true) }
  scope :alphabetical, -> { order(:name) }
  
  # ============================================================================
  # CLASS METHODS
  # ============================================================================
  
  def self.find_by_slug!(slug)
    find_by!(slug: slug)
  end
  
  # ============================================================================
  # INSTANCE METHODS
  # ============================================================================
  
  def system_role?
    !is_custom
  end
  
  def custom_role?
    is_custom
  end
  
  def add_permission(permission)
    permissions << permission unless permissions.include?(permission)
  end
  
  def remove_permission(permission)
    permissions.delete(permission)
  end
  
  def has_permission?(permission_name)
    permissions.exists?(name: permission_name)
  end
  
  def to_param
    slug
  end
  
  private
  
  def generate_slug
    self.slug = name.parameterize(separator: '_')
  end
  
  def system_role_cannot_be_deleted
    if system_role?
      errors.add(:base, 'System roles cannot be deleted')
      throw(:abort)
    end
  end
end
```

### app/models/permission.rb

```ruby
class Permission < ApplicationRecord
  # ============================================================================
  # CONSTANTS
  # ============================================================================
  ACTIONS = %w[create read update delete manage].freeze
  
  RESOURCES = %w[
    bookings courts venues users roles reports settings
    pricing closures notifications
  ].freeze
  
  # ============================================================================
  # ASSOCIATIONS
  # ============================================================================
  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions
  
  # ============================================================================
  # VALIDATIONS
  # ============================================================================
  validates :resource, presence: true
  validates :action, presence: true
  validates :name, presence: true, uniqueness: true
  validates :resource, inclusion: { in: RESOURCES }
  validates :action, inclusion: { in: ACTIONS }
  
  validate :name_matches_resource_and_action
  
  # ============================================================================
  # CALLBACKS
  # ============================================================================
  before_validation :generate_name, if: -> { name.blank? && resource.present? && action.present? }
  
  # ============================================================================
  # SCOPES
  # ============================================================================
  scope :for_resource, ->(resource) { where(resource: resource) }
  scope :for_action, ->(action) { where(action: action) }
  scope :alphabetical, -> { order(:name) }
  
  # ============================================================================
  # CLASS METHODS
  # ============================================================================
  
  def self.find_by_name!(name)
    find_by!(name: name)
  end
  
  # ============================================================================
  # INSTANCE METHODS
  # ============================================================================
  
  def to_s
    name
  end
  
  private
  
  def generate_name
    self.name = "#{action}:#{resource}"
  end
  
  def name_matches_resource_and_action
    return if name.blank? || resource.blank? || action.blank?
    
    expected_name = "#{action}:#{resource}"
    unless name == expected_name
      errors.add(:name, "must be '#{expected_name}' based on resource and action")
    end
  end
end
```

### app/models/role_permission.rb

```ruby
class RolePermission < ApplicationRecord
  # ============================================================================
  # ASSOCIATIONS
  # ============================================================================
  belongs_to :role
  belongs_to :permission
  
  # ============================================================================
  # VALIDATIONS
  # ============================================================================
  validates :role_id, uniqueness: { scope: :permission_id }
end
```

### app/models/user_role.rb

```ruby
class UserRole < ApplicationRecord
  # ============================================================================
  # ASSOCIATIONS
  # ============================================================================
  belongs_to :user
  belongs_to :role
  belongs_to :assigned_by, class_name: 'User', optional: true
  
  # ============================================================================
  # VALIDATIONS
  # ============================================================================
  validates :user_id, uniqueness: { scope: :role_id }
  validates :assigned_at, presence: true
  
  # ============================================================================
  # CALLBACKS
  # ============================================================================
  before_validation :set_assigned_at, if: :new_record?
  
  # ============================================================================
  # SCOPES
  # ============================================================================
  scope :recent, -> { order(assigned_at: :desc) }
  
  private
  
  def set_assigned_at
    self.assigned_at ||= Time.current
  end
end
```

### Update app/models/user.rb

Add these associations and methods to the User model:

```ruby
# In app/models/user.rb, add to ASSOCIATIONS section:
has_many :user_roles, dependent: :destroy
has_many :roles, through: :user_roles

# Add to INSTANCE METHODS section:

def assign_role(role, assigned_by: nil)
  user_roles.find_or_create_by!(role: role) do |ur|
    ur.assigned_by = assigned_by
  end
end

def remove_role(role)
  user_roles.find_by(role: role)&.destroy
end

def has_role?(role_name)
  roles.exists?(slug: role_name)
end

def has_permission?(permission_name)
  return true if is_global_admin?
  
  permissions.exists?(name: permission_name)
end

def permissions
  Permission.joins(roles: :users).where(users: { id: id }).distinct
end

def can?(action, resource)
  permission_name = "#{action}:#{resource}"
  has_permission?(permission_name) || has_permission?("manage:#{resource}")
end

def owner?
  has_role?('owner')
end

def admin?
  has_role?('admin')
end

def receptionist?
  has_role?('receptionist')
end

def staff?
  has_role?('staff')
end

def customer?
  has_role?('customer')
end
```

---

## Seed Data

**File**: `db/seeds/04_roles_permissions.rb`

```ruby
puts "🌱 Seeding Phase 4: Roles & Permissions..."

# ============================================================
# PERMISSIONS
# ============================================================
permissions_data = {
  bookings: %w[create read update delete manage],
  courts: %w[create read update delete],
  venues: %w[read update manage],
  users: %w[create read update delete],
  roles: %w[create read update delete],
  reports: %w[read manage],
  settings: %w[read update],
  pricing: %w[create read update delete],
  closures: %w[create read update delete],
  notifications: %w[read create]
}

permissions = {}
permissions_data.each do |resource, actions|
  actions.each do |action|
    permission = Permission.find_or_create_by!(
      resource: resource.to_s,
      action: action
    ) do |p|
      p.description = "Can #{action} #{resource}"
    end
    permissions["#{action}:#{resource}"] = permission
    puts "  ✅ Created permission: #{permission.name}"
  end
end

# ============================================================
# SYSTEM ROLES
# ============================================================

# OWNER Role
owner_role = Role.find_or_create_by!(slug: 'owner') do |r|
  r.name = 'Owner'
  r.description = 'Venue owner with full control'
  r.is_custom = false
end

# Owner gets ALL permissions
Permission.all.each do |permission|
  owner_role.add_permission(permission)
end

puts "  ✅ Created role: Owner (#{owner_role.permissions.count} permissions)"

# ADMIN Role
admin_role = Role.find_or_create_by!(slug: 'admin') do |r|
  r.name = 'Admin'
  r.description = 'Administrator with most permissions'
  r.is_custom = false
end

admin_permissions = [
  'manage:bookings', 'manage:courts', 'create:users', 'read:users', 
  'update:users', 'read:roles', 'manage:reports', 'read:settings', 
  'update:settings', 'manage:pricing', 'manage:closures', 
  'read:notifications', 'create:notifications', 'read:venues', 'update:venues'
]

admin_permissions.each do |perm_name|
  admin_role.add_permission(permissions[perm_name]) if permissions[perm_name]
end

puts "  ✅ Created role: Admin (#{admin_role.permissions.count} permissions)"

# RECEPTIONIST Role
receptionist_role = Role.find_or_create_by!(slug: 'receptionist') do |r|
  r.name = 'Receptionist'
  r.description = 'Front desk staff managing bookings'
  r.is_custom = false
end

receptionist_permissions = [
  'manage:bookings', 'read:courts', 'create:closures', 'read:closures',
  'read:users', 'read:reports', 'read:settings', 'read:notifications'
]

receptionist_permissions.each do |perm_name|
  receptionist_role.add_permission(permissions[perm_name]) if permissions[perm_name]
end

puts "  ✅ Created role: Receptionist (#{receptionist_role.permissions.count} permissions)"

# STAFF Role
staff_role = Role.find_or_create_by!(slug: 'staff') do |r|
  r.name = 'Staff'
  r.description = 'General staff with basic access'
  r.is_custom = false
end

staff_permissions = [
  'read:bookings', 'read:courts', 'read:users',
  'read:closures', 'read:notifications'
]

staff_permissions.each do |perm_name|
  staff_role.add_permission(permissions[perm_name]) if permissions[perm_name]
end

puts "  ✅ Created role: Staff (#{staff_role.permissions.count} permissions)"

# CUSTOMER Role
customer_role = Role.find_or_create_by!(slug: 'customer') do |r|
  r.name = 'Customer'
  r.description = 'Regular user who books courts'
  r.is_custom = false
end

customer_permissions = [
  'create:bookings', 'read:bookings', 'update:bookings',
  'read:courts', 'read:notifications'
]

customer_permissions.each do |perm_name|
  customer_role.add_permission(permissions[perm_name]) if permissions[perm_name]
end

puts "  ✅ Created role: Customer (#{customer_role.permissions.count} permissions)"

# ============================================================
# ASSIGN ROLES TO USERS
# ============================================================

# Assign owner role to venue owner
owner_user = User.find_by(email: 'owner@example.com')
if owner_user
  owner_user.assign_role(owner_role)
  puts "  ✅ Assigned 'owner' role to #{owner_user.email}"
end

# Assign customer role to test customers
['ali@example.com', 'sara@example.com', 'omar@example.com'].each do |email|
  customer_user = User.find_by(email: email)
  if customer_user
    customer_user.assign_role(customer_role)
    puts "  ✅ Assigned 'customer' role to #{customer_user.email}"
  end
end

# Create a receptionist user
receptionist_user = User.find_or_create_by!(email: 'receptionist@example.com') do |user|
  user.first_name = 'Sarah'
  user.last_name = 'Receptionist'
  user.password = 'password123'
  user.phone_number = '+92 333 7778888'
  user.is_active = true
end
receptionist_user.assign_role(receptionist_role, assigned_by: owner_user)
puts "  ✅ Created receptionist user and assigned role"

puts "\n✅ Phase 4 seeding complete!"
puts "  👥 Roles: #{Role.count}"
puts "  🔑 Permissions: #{Permission.count}"
puts "  🔗 Role-Permission assignments: #{RolePermission.count}"
puts "  👤 User-Role assignments: #{UserRole.count}"
```

---

## Testing

**File**: `spec/models/user_spec.rb` (add to existing file)

```ruby
describe 'roles and permissions' do
  let(:user) { create(:user) }
  let(:owner_role) { create(:role, slug: 'owner') }
  let(:customer_role) { create(:role, slug: 'customer') }
  let(:create_bookings_permission) { create(:permission, name: 'create:bookings') }
  
  describe '#assign_role' do
    it 'assigns role to user' do
      user.assign_role(customer_role)
      expect(user.roles).to include(customer_role)
    end
    
    it 'does not duplicate role assignment' do
      user.assign_role(customer_role)
      user.assign_role(customer_role)
      expect(user.user_roles.count).to eq(1)
    end
  end
  
  describe '#has_role?' do
    it 'returns true when user has role' do
      user.assign_role(customer_role)
      expect(user.has_role?('customer')).to be true
    end
    
    it 'returns false when user does not have role' do
      expect(user.has_role?('admin')).to be false
    end
  end
  
  describe '#can?' do
    it 'returns true when user has specific permission' do
      customer_role.add_permission(create_bookings_permission)
      user.assign_role(customer_role)
      expect(user.can?(:create, :bookings)).to be true
    end
    
    it 'returns false when user lacks permission' do
      user.assign_role(customer_role)
      expect(user.can?(:delete, :venues)).to be false
    end
    
    it 'returns true for global admins regardless of permissions' do
      user.update(is_global_admin: true)
      expect(user.can?(:delete, :venues)).to be true
    end
  end
end
```

---

## Authorization Setup (Optional)

If using Pundit gem for authorization:

**File**: `app/policies/application_policy.rb`

```ruby
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError
    end

    private

    attr_reader :user, :scope
  end
end
```

**File**: `app/policies/booking_policy.rb`

```ruby
class BookingPolicy < ApplicationPolicy
  def index?
    user.can?(:read, :bookings)
  end

  def show?
    user.can?(:read, :bookings) || record.user_id == user.id
  end

  def create?
    user.can?(:create, :bookings)
  end

  def update?
    user.can?(:update, :bookings) || record.user_id == user.id
  end

  def destroy?
    user.can?(:delete, :bookings)
  end

  class Scope < Scope
    def resolve
      if user.can?(:manage, :bookings)
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
```

---

## Checklist

Before moving to Phase 5, ensure:

- [ ] All four migrations run successfully
- [ ] Roles table has system roles (owner, admin, receptionist, staff, customer)
- [ ] Permissions table has all permissions seeded
- [ ] Role-permission assignments created
- [ ] User-role assignments working
- [ ] User#can? method working correctly
- [ ] Global admins bypass permission checks
- [ ] System roles cannot be deleted
- [ ] Custom roles can be created and deleted
- [ ] Tests passing

---

## Next Phase

Once Phase 4 is complete, proceed to:
👉 **[Phase 5: Booking System](DB_PHASE_5_BOOKINGS.md)**

---

*Last Updated: 2026-04-07*
