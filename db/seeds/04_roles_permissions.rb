# frozen_string_literal: true

puts "🌱 Seeding Phase 4: Roles & Permissions..."

# ============================================================
# PERMISSIONS (global, reusable across all venues)
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
    permission = Permission.find_or_create_by!(resource: resource.to_s, action: action)
    permissions["#{action}:#{resource}"] = permission
    puts "  ✅ Created permission: #{action}:#{resource}"
  end
end

# ============================================================
# VENUE-SCOPED ROLES
# Seeded for the first venue. Each venue manages its own roles.
# ============================================================
venue = Venue.first
unless venue
  puts "  ⚠️  No venue found — skipping role seeding. Run venue seeds first."
  return
end

puts "\n  📍 Creating roles for venue: #{venue.name}"

# Manager role — full operational access
manager_role = Role.find_or_create_by!(name: "Manager", venue: venue)
manager_permissions = %w[
  read:venues update:venues
  create:bookings read:bookings update:bookings
  create:courts read:courts update:courts delete:courts
  create:roles read:roles update:roles delete:roles
  read:users update:users create:users delete:users
]
manager_permissions.each do |key|
  manager_role.add_permission(permissions[key]) if permissions[key]
end
puts "  ✅ Created role: Manager (#{manager_role.permissions.count} permissions)"

# Receptionist role — booking and closure management
receptionist_role = Role.find_or_create_by!(name: "Receptionist", venue: venue)
receptionist_permissions = %w[read:venues create:bookings read:bookings update:bookings read:courts read:roles read:users]
receptionist_permissions.each do |key|
  receptionist_role.add_permission(permissions[key]) if permissions[key]
end
puts "  ✅ Created role: Receptionist (#{receptionist_role.permissions.count} permissions)"

# Staff role — read-only operational access
staff_role = Role.find_or_create_by!(name: "Staff", venue: venue)
staff_permissions = %w[read:bookings read:courts read:users read:closures read:notifications]
staff_permissions.each do |key|
  staff_role.add_permission(permissions[key]) if permissions[key]
end
puts "  ✅ Created role: Staff (#{staff_role.permissions.count} permissions)"

puts "\n✅ Phase 4 seeding complete!"
puts "  👔 Roles: #{Role.count}"
puts "  🔑 Permissions: #{Permission.count}"
puts "  🔗 Role-Permission assignments: #{RolePermission.count}"
