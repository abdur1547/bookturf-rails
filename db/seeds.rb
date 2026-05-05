# Bookturf Database Seeds
# This file loads all seed data in the correct order for MVP
#
# Run individual phases:
#   rails runner db/seeds/01_users.rb
#   rails runner db/seeds/02_venues.rb
#   rails runner db/seeds/03_courts.rb
#   rails runner db/seeds/04_roles_permissions.rb
#   rails runner db/seeds/05_bookings.rb
#   rails runner db/seeds/06_closures_notifications.rb
#
# Or run all at once:
#   rails db:seed

puts "🌱 Starting Bookturf Database Seeding..."
puts "=" * 60

# Phase 1: Users
load Rails.root.join('db', 'seeds', '01_users.rb')
puts ""

# Phase 2: Venues
load Rails.root.join('db', 'seeds', '02_venues.rb')
puts ""

# Phase 3: Court Types and Courts (must run before bookings)
load Rails.root.join('db', 'seeds', '03_courts.rb')
puts ""

# Phase 4: Roles & Permissions
load Rails.root.join('db', 'seeds', '04_roles_permissions.rb')
puts ""

# Phase 5: Bookings
load Rails.root.join('db', 'seeds', '05_bookings.rb')
puts ""

# Phase 6: Court Closures & Notifications
load Rails.root.join('db', 'seeds', '06_closures_notifications.rb')
puts ""

puts "=" * 60
puts "✅ All seeding complete!"
puts ""
puts "📊 Database Summary:"
puts "  👥 Users: #{User.count}"
puts "  🏢 Venues: #{Venue.count}"
puts "  🏟️  Courts: #{Court.count}"
puts "  🎾 Court Types: #{CourtType.count}"
puts "  💰 Pricing Rules: #{PricingRule.count}"
puts "  👔 Roles: #{Role.count}"
puts "  🔐 Permissions: #{Permission.count}"
puts "  📅 Bookings: #{Booking.count}"
puts "  🤝 Memberships: #{VenueMembership.count}"
puts "  📝 Activity Logs: #{PublicActivity::Activity.count}"
puts "  🔒 Court Closures: #{CourtClosure.count}"
puts "  📬 Notifications: #{Notification.count}"
puts ""
puts "🚀 Your Bookturf application is ready!"
