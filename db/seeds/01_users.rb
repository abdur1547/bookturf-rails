puts "🌱 Seeding Phase 1: Users..."

# Venue owner
owner = User.find_or_create_by!(email: 'owner@example.com') do |u|
  u.full_name = 'Venue Owner'
  u.phone_number = '+92 300 1111111'
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.system_role = :normal
end
puts "  ✅ Created user: #{owner.email}"

# Super admin
admin = User.find_or_create_by!(email: 'admin@bookturf.com') do |u|
  u.full_name = 'Super Admin'
  u.phone_number = '+92 300 2222222'
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.system_role = :super_admin
end
puts "  ✅ Created user: #{admin.email} (super_admin)"

# Customers
3.times do |i|
  customer = User.find_or_create_by!(email: "customer#{i + 1}@example.com") do |u|
    u.full_name = "Customer #{i + 1}"
    u.phone_number = "+92 300 300#{i + 1}00#{i + 1}"
    u.password = 'password123'
    u.password_confirmation = 'password123'
    u.system_role = :normal
  end
  puts "  ✅ Created user: #{customer.email}"
end

puts "\n✅ Phase 1 seeding complete!"
puts "  👥 Users: #{User.count}"
