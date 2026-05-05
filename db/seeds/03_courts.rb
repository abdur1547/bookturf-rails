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
  { name: 'Badminton Court 1', type: 'badminton' },
  { name: 'Badminton Court 2', type: 'badminton' },
  { name: 'Badminton Court 3', type: 'badminton' },
  { name: 'Tennis Court 1', type: 'tennis' },
  { name: 'Tennis Court 2', type: 'tennis' },
  { name: 'Basketball Court', type: 'basketball' }
]

courts_data.each do |data|
  court = Court.find_or_create_by!(venue: venue, name: data[:name]) do |c|
    c.court_type = court_types[data[:type]]
    c.is_active = true
    c.description = "Premium #{court_types[data[:type]].name} court with professional flooring"
  end
  puts "  ✅ Created court: #{court.full_name}"
end

# ============================================================
# PRICING RULES (per court)
# ============================================================

Court.where(venue: venue, court_type: court_types['badminton']).each do |court|
  PricingRule.find_or_create_by!(venue: venue, court: court, name: 'Weekday Morning') do |pr|
    pr.price_per_hour = 1500; pr.start_time = '06:00'; pr.end_time = '12:00'; pr.priority = 1; pr.is_active = true
  end
  PricingRule.find_or_create_by!(venue: venue, court: court, name: 'Weekday Evening (Peak)') do |pr|
    pr.price_per_hour = 2500; pr.start_time = '18:00'; pr.end_time = '23:00'; pr.priority = 2; pr.is_active = true
  end
end
puts "  ✅ Created pricing rules for Badminton courts"

Court.where(venue: venue, court_type: court_types['tennis']).each do |court|
  PricingRule.find_or_create_by!(venue: venue, court: court, name: 'Standard Rate') do |pr|
    pr.price_per_hour = 3000; pr.priority = 0; pr.is_active = true
  end
end
puts "  ✅ Created pricing rules for Tennis courts"

Court.where(venue: venue, court_type: court_types['basketball']).each do |court|
  PricingRule.find_or_create_by!(venue: venue, court: court, name: 'Standard Rate') do |pr|
    pr.price_per_hour = 2500; pr.priority = 0; pr.is_active = true
  end
end
puts "  ✅ Created pricing rules for Basketball courts"

puts "\n✅ Phase 3 seeding complete!"
puts "  📊 Court Types: #{CourtType.count}"
puts "  🏟️  Courts: #{Court.count}"
puts "  💰 Pricing Rules: #{PricingRule.count}"
