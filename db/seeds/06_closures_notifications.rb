puts "🌱 Seeding Phase 6: Court Closures & Notifications..."

venue = Venue.first
courts = Court.all
admin = User.find_by(email: 'owner@example.com')

unless venue && courts.any? && admin
  puts "  ⚠️  Missing required data. Run previous phase seeds first."
  exit
end

# ============================================================
# COURT CLOSURES
# ============================================================

# Past closure - Completed maintenance
past_closure = CourtClosure.create!(
  court: courts.first,
  venue: venue,
  title: 'Floor Maintenance (Completed)',
  description: 'Annual floor polishing and maintenance - Completed successfully',
  start_time: 2.days.ago.in_time_zone.change(hour: 6),
  end_time: 2.days.ago.in_time_zone.change(hour: 9),
  created_by: admin
)
puts "  ✅ Created past closure: #{past_closure.title} (#{past_closure.formatted_date_range})"

# Today's closure - Ongoing
today_closure = CourtClosure.create!(
  court: courts.second,
  venue: venue,
  title: 'Equipment Repair',
  description: 'Replacing damaged net and poles',
  start_time: Date.current.in_time_zone.change(hour: 8),
  end_time: Date.current.in_time_zone.change(hour: 10),
  created_by: admin
)
puts "  ✅ Created today's closure: #{today_closure.title} (#{today_closure.formatted_date_range})"

# Tomorrow's closure - Scheduled maintenance
tomorrow = Date.tomorrow
tomorrow_closure = CourtClosure.create!(
  court: courts.third,
  venue: venue,
  title: 'Light Fixture Service',
  description: 'Routine inspection and cleaning of ceiling lights',
  start_time: tomorrow.in_time_zone.change(hour: 13),
  end_time: tomorrow.in_time_zone.change(hour: 15),
  created_by: admin
)
puts "  ✅ Created tomorrow's closure: #{tomorrow_closure.title} (#{tomorrow_closure.formatted_date_range})"

# Weekend closure - Special event
weekend = Date.current.next_occurring(:saturday)
weekend_closure = CourtClosure.create!(
  court: courts.last,
  venue: venue,
  title: 'Private Tournament',
  description: 'Court reserved for inter-school badminton tournament',
  start_time: weekend.in_time_zone.change(hour: 9),
  end_time: weekend.in_time_zone.change(hour: 18),
  created_by: admin
)
puts "  ✅ Created weekend closure: #{weekend_closure.title} (#{weekend_closure.formatted_date_range})"

# ============================================================
# NOTIFICATIONS
# ============================================================

# Booking confirmation notifications (auto-created via callback)
# Count existing notifications from bookings
booking_notifications_count = Notification.where(notification_type: 'booking_confirmed').count
puts "  📬 #{booking_notifications_count} booking confirmation notifications (auto-generated from bookings)"

# Create venue announcements for users with bookings
users_with_bookings = User.joins(:bookings).distinct

announcement_count = 0
users_with_bookings.each do |user|
  Notification.venue_announcement(
    user,
    venue,
    'New Extended Weekend Hours!',
    'Great news! Starting next month, we will extend weekend hours till midnight. Book your late night sessions now and enjoy 20% off on first booking!'
  )
  announcement_count += 1
end
puts "  ✅ Created #{announcement_count} venue announcement notifications"

# Create booking reminders for upcoming bookings (tomorrow)
upcoming_bookings = Booking.upcoming.where('start_time >= ? AND start_time < ?', 1.day.from_now, 2.days.from_now)
reminder_count = 0

upcoming_bookings.each do |booking|
  # Only create reminder if it doesn't already exist
  unless Notification.exists?(booking: booking, notification_type: 'booking_reminder')
    Notification.booking_reminder(booking)
    reminder_count += 1
  end
end
puts "  ✅ Created #{reminder_count} booking reminder notifications"

# Create system alert for all users
system_alert_count = 0
users_with_bookings.limit(5).each do |user|
  Notification.create!(
    user: user,
    venue: venue,
    notification_type: 'system_alert',
    title: 'System Maintenance Notice',
    message: 'Our online booking system will undergo scheduled maintenance this Sunday from 2 AM to 4 AM. During this time, online bookings will be unavailable. Please plan accordingly.',
    priority: 'high'
  )
  system_alert_count += 1
end
puts "  ✅ Created #{system_alert_count} system alert notifications"

# Create court closure notifications for affected users
closure_notification_count = 0
if weekend_closure.present?
  # Find users who might be affected (future feature)
  users_with_bookings.limit(3).each do |user|
    Notification.create!(
      user: user,
      venue: venue,
      notification_type: 'court_closure',
      title: "Court Closure: #{weekend_closure.title}",
      message: "#{weekend_closure.court.full_name} will be closed on #{weekend_closure.formatted_date_range} for #{weekend_closure.title.downcase}. #{weekend_closure.description}",
      priority: 'normal'
    )
    closure_notification_count += 1
  end
end
puts "  ✅ Created #{closure_notification_count} court closure notifications"

# Mark some notifications as read (simulate user activity)
read_count = 0
Notification.unread.limit(Notification.count / 2).each do |notification|
  notification.mark_as_read!
  read_count += 1
end
puts "  ✅ Marked #{read_count} notifications as read"

puts "\n✅ Phase 6 seeding complete!"
puts "  🔒 Court Closures: #{CourtClosure.count}"
puts "    - Active: #{CourtClosure.active.count}"
puts "    - Past: #{CourtClosure.past.count}"
puts "    - Current: #{CourtClosure.current.count}"
puts "    - Upcoming: #{CourtClosure.upcoming.count}"
puts ""
puts "  📬 Notifications: #{Notification.count}"
puts "    - Unread: #{Notification.unread.count}"
puts "    - Read: #{Notification.read.count}"
puts "    - By Type:"
Notification.group(:notification_type).count.each do |type, count|
  puts "      * #{type}: #{count}"
end
puts "    - By Priority:"
Notification.group(:priority).count.each do |priority, count|
  puts "      * #{priority}: #{count}"
end
