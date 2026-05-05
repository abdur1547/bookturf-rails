puts "🌱 Seeding Phase 2: Venues..."

owner = User.find_by!(email: 'owner@example.com')

venue = Venue.find_or_create_by!(owner: owner) do |v|
  v.name = 'Bookturf Sports Arena'
  v.address = 'Plot 5, Block 4, Clifton, Karachi'
  v.city = 'Karachi'
  v.state = 'Sindh'
  v.country = 'Pakistan'
  v.postal_code = '75600'
  v.phone_number = '+92 21 35000001'
  v.email = 'arena@bookturf.com'
  v.latitude = 24.8175
  v.longitude = 67.0297
  v.timezone = 'Asia/Karachi'
  v.currency = 'PKR'
  v.is_active = true
end
puts "  ✅ Created venue: #{venue.name} (#{venue.slug})"

# Operating hours (Mon–Fri 6am–11pm, Sat–Sun 8am–10pm)
(0..6).each do |day|
  VenueOperatingHour.find_or_create_by!(venue: venue, day_of_week: day) do |h|
    weekend = day == 0 || day == 6
    h.opens_at = weekend ? '08:00' : '06:00'
    h.closes_at = weekend ? '22:00' : '23:00'
    h.is_closed = false
  end
end
puts "  ✅ Created operating hours for #{venue.name}"

puts "\n✅ Phase 2 seeding complete!"
puts "  🏢 Venues: #{Venue.count}"
