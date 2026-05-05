puts "🌱 Seeding Phase 5: Bookings..."

venue = Venue.first
courts = Court.all
customers = User.where.not(email: [ 'admin@bookturf.com', 'owner@example.com', 'receptionist@example.com' ])

unless venue && courts.any? && customers.any?
  puts "  ⚠️  Missing required data. Run previous phase seeds first."
  exit
end

# ============================================================
# BOOKINGS - Today's Bookings
# ============================================================

# Create bookings for today
today = Date.current
booking_count = 0

# Morning bookings (9 AM, 10 AM, 11 AM)
[ 9, 10, 11 ].each_with_index do |hour, index|
  court = courts[index % courts.count]
  customer = customers[index % customers.count]
  start_time = today.in_time_zone.change(hour: hour)
  end_time = start_time + 1.hour

  booking = Booking.create!(
    user: customer,
    court: court,
    venue: venue,
    start_time: start_time,
    end_time: end_time,
    status: 'confirmed',
    payment_method: 'cash',
    payment_status: 'pending',
    created_by: customer,
    notes: "Morning session - Created via seed data"
  )

  puts "  ✅ Created booking: #{booking.booking_number} (#{booking.formatted_time_slot})"
  booking_count += 1
end

# Afternoon bookings (2 PM, 3 PM, 4 PM)
[ 14, 15, 16 ].each_with_index do |hour, index|
  court = courts[index % courts.count]
  customer = customers[(index + 1) % customers.count]
  start_time = today.in_time_zone.change(hour: hour)
  end_time = start_time + 1.hour

  booking = Booking.create!(
    user: customer,
    court: court,
    venue: venue,
    start_time: start_time,
    end_time: end_time,
    status: 'confirmed',
    payment_method: 'cash',
    payment_status: 'pending',
    created_by: customer,
    notes: "Afternoon session - Created via seed data"
  )

  puts "  ✅ Created booking: #{booking.booking_number} (#{booking.formatted_time_slot})"
  booking_count += 1
end

# Evening bookings (6 PM, 7 PM, 8 PM) - Peak hours
[ 18, 19, 20 ].each_with_index do |hour, index|
  court = courts[index % courts.count]
  customer = customers[(index + 2) % customers.count]
  start_time = today.in_time_zone.change(hour: hour)
  end_time = start_time + 1.hour

  booking = Booking.create!(
    user: customer,
    court: court,
    venue: venue,
    start_time: start_time,
    end_time: end_time,
    status: 'confirmed',
    payment_method: 'cash',
    payment_status: 'pending',
    created_by: customer,
    notes: "Evening peak session - Created via seed data"
  )

  puts "  ✅ Created booking: #{booking.booking_number} (#{booking.formatted_time_slot})"
  booking_count += 1
end

# ============================================================
# PAST BOOKINGS - Completed & Paid
# ============================================================

yesterday = Date.yesterday
[ 10, 14, 18 ].each_with_index do |hour, index|
  court = courts[index % courts.count]
  customer = customers[index % customers.count]
  start_time = yesterday.in_time_zone.change(hour: hour)
  end_time = start_time + 1.hour

  booking = Booking.create!(
    user: customer,
    court: court,
    venue: venue,
    start_time: start_time,
    end_time: end_time,
    status: 'confirmed',
    payment_method: 'cash',
    payment_status: 'paid',
    paid_amount: 0, # Will be set by mark_paid!
    created_by: customer,
    notes: "Past session - Completed"
  )

  # Mark as paid (using update_columns to bypass PublicActivity BigDecimal serialization)
  booking.update_columns(payment_status: 'paid', paid_amount: booking.total_amount || 0)

  puts "  ✅ Created past booking: #{booking.booking_number} (Completed & Paid)"
  booking_count += 1
end

# ============================================================
# CANCELLED BOOKING
# ============================================================

cancelled_booking = Booking.create!(
  user: customers.last,
  court: courts.first,
  venue: venue,
  start_time: today.in_time_zone.change(hour: 21),
  end_time: today.in_time_zone.change(hour: 22),
  status: 'confirmed',
  payment_method: 'cash',
  payment_status: 'pending',
  created_by: customers.last,
  notes: "To be cancelled"
)

cancelled_booking.cancel!(
  reason: 'Personal emergency - unable to attend',
  cancelled_by: customers.last
)

puts "  ✅ Created cancelled booking: #{cancelled_booking.booking_number}"
booking_count += 1

# ============================================================
# FUTURE BOOKINGS - Tomorrow
# ============================================================

tomorrow = Date.tomorrow
[ 9, 15, 19 ].each_with_index do |hour, index|
  court = courts[index % courts.count]
  customer = customers[(index + 1) % customers.count]
  start_time = tomorrow.in_time_zone.change(hour: hour)
  end_time = start_time + 1.hour

  booking = Booking.create!(
    user: customer,
    court: court,
    venue: venue,
    start_time: start_time,
    end_time: end_time,
    status: 'confirmed',
    payment_method: 'cash',
    payment_status: 'pending',
    created_by: customer,
    notes: "Future booking for tomorrow"
  )

  puts "  ✅ Created future booking: #{booking.booking_number} (Tomorrow)"
  booking_count += 1
end

# ============================================================
# NO-SHOW BOOKING
# ============================================================

no_show_booking = Booking.create!(
  user: customers.first,
  court: courts.last,
  venue: venue,
  start_time: yesterday.in_time_zone.change(hour: 20),
  end_time: yesterday.in_time_zone.change(hour: 21),
  status: 'confirmed',
  payment_method: 'cash',
  payment_status: 'pending',
  created_by: customers.first
)

no_show_booking.update_columns(status: 'no_show')
puts "  ✅ Created no-show booking: #{no_show_booking.booking_number}"
booking_count += 1

puts "\n✅ Phase 5 seeding complete!"
puts "  📅 Total bookings: #{Booking.count}"
puts "  ✅ Confirmed: #{Booking.confirmed.count}"
puts "  ✔️  Completed: #{Booking.completed.count}"
puts "  ❌ Cancelled: #{Booking.cancelled.count}"
puts "  👻 No-show: #{Booking.no_show.count}"
puts "  📝 Activity logs: #{PublicActivity::Activity.where(trackable_type: 'Booking').count}"
puts "  💰 Total amount (all bookings): PKR #{Booking.sum(:total_amount).round(2)}"
puts "  💵 Paid amount: PKR #{Booking.sum(:paid_amount).round(2)}"
