# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:first_name) { |n| "User" }
    sequence(:last_name) { |n| "Name#{n}" }
    phone_number { "+92 300 1234567" }
    password { "password123" }
    password_confirmation { "password123" }
    is_active { true }
    is_global_admin { false }

    trait :with_google_oauth do
      provider { "google_oauth2" }
      sequence(:uid) { |n| "google-uid-#{n}" }
      avatar_url { "https://example.com/avatar.jpg" }
    end

    trait :inactive do
      is_active { false }
    end

    trait :global_admin do
      is_global_admin { true }
    end

    trait :with_emergency_contact do
      emergency_contact_name { "Emergency Contact" }
      emergency_contact_phone { "+92 300 9876543" }
    end

    # System role traits - automatically assign role with permissions
    trait :owner do
      after(:create) do |user|
        role = Role.find_or_create_by!(slug: 'owner') do |r|
          r.name = 'Owner'
          r.description = 'Venue owner with full control'
          r.is_custom = false
        end

        # Owner gets ALL permissions
        Permission.all.each do |permission|
          role.add_permission(permission)
        end

        user.assign_role(role)
      end
    end

    trait :admin do
      after(:create) do |user|
        role = Role.find_or_create_by!(slug: 'admin') do |r|
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
          resource, action = perm_name.split(':').reverse
          permission = Permission.find_or_create_by!(resource: resource, action: action)
          role.add_permission(permission)
        end

        user.assign_role(role)
      end
    end

    trait :receptionist do
      after(:create) do |user|
        role = Role.find_or_create_by!(slug: 'receptionist') do |r|
          r.name = 'Receptionist'
          r.description = 'Front desk staff managing bookings'
          r.is_custom = false
        end

        receptionist_permissions = [
          'manage:bookings', 'read:courts', 'create:closures', 'read:closures',
          'read:users', 'read:reports', 'read:settings', 'read:notifications'
        ]

        receptionist_permissions.each do |perm_name|
          resource, action = perm_name.split(':').reverse
          permission = Permission.find_or_create_by!(resource: resource, action: action)
          role.add_permission(permission)
        end

        user.assign_role(role)
      end
    end

    trait :staff do
      after(:create) do |user|
        role = Role.find_or_create_by!(slug: 'staff') do |r|
          r.name = 'Staff'
          r.description = 'General staff with basic access'
          r.is_custom = false
        end

        staff_permissions = [
          'read:bookings', 'read:courts', 'read:users',
          'read:closures', 'read:notifications'
        ]

        staff_permissions.each do |perm_name|
          resource, action = perm_name.split(':').reverse
          permission = Permission.find_or_create_by!(resource: resource, action: action)
          role.add_permission(permission)
        end

        user.assign_role(role)
      end
    end

    trait :customer do
      after(:create) do |user|
        role = Role.find_or_create_by!(slug: 'customer') do |r|
          r.name = 'Customer'
          r.description = 'Regular user who books courts'
          r.is_custom = false
        end

        customer_permissions = [
          'create:bookings', 'read:bookings', 'update:bookings',
          'read:courts', 'read:notifications'
        ]

        customer_permissions.each do |perm_name|
          resource, action = perm_name.split(':').reverse
          permission = Permission.find_or_create_by!(resource: resource, action: action)
          role.add_permission(permission)
        end

        user.assign_role(role)
      end
    end

    # Trait for custom role - assign a custom role without predefined permissions
    trait :with_custom_role do
      transient do
        role_name { "Custom Role" }
        role_slug { nil }
        permissions { [] }
      end

      after(:create) do |user, evaluator|
        slug = evaluator.role_slug || evaluator.role_name.parameterize.underscore
        role = Role.find_or_create_by!(slug: slug) do |r|
          r.name = evaluator.role_name
          r.description = "Custom role for testing"
          r.is_custom = true
        end

        evaluator.permissions.each do |perm_name|
          resource, action = perm_name.split(':').reverse
          permission = Permission.find_or_create_by!(resource: resource, action: action)
          role.add_permission(permission)
        end

        user.assign_role(role)
      end
    end
  end
end
