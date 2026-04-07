# Bookturf Database Implementation Guide

**Project**: Bookturf - Sports Court Booking Management System  
**Database**: PostgreSQL  
**Framework**: Ruby on Rails 7.1  
**Last Updated**: 2026-04-07

---

## 📚 Overview

This guide divides the database implementation into **6 progressive phases**. Each phase builds upon the previous one, allowing for incremental development and testing.

**Total Estimated Time**: 15-20 days  
**Recommended Approach**: Complete one phase fully before moving to the next

---

## 🗂️ Implementation Phases

<table>
<tr>
<th>Phase</th>
<th>Focus Area</th>
<th>Tables</th>
<th>Time</th>
<th>Status</th>
</tr>

<tr>
<td><strong>1</strong></td>
<td>Authentication & Users</td>
<td>users</td>
<td>1-2 days</td>
<td>Foundation</td>
</tr>

<tr>
<td><strong>2</strong></td>
<td>Venue Setup</td>
<td>venues, venue_settings, venue_operating_hours</td>
<td>2-3 days</td>
<td>Core Infrastructure</td>
</tr>

<tr>
<td><strong>3</strong></td>
<td>Court Management</td>
<td>court_types, courts, pricing_rules</td>
<td>2-3 days</td>
<td>Core Features</td>
</tr>

<tr>
<td><strong>4</strong></td>
<td>Roles & Permissions</td>
<td>roles, permissions, role_permissions, user_roles</td>
<td>3-4 days</td>
<td>Access Control</td>
</tr>

<tr>
<td><strong>5</strong></td>
<td>Booking System</td>
<td>bookings, booking_logs</td>
<td>4-5 days</td>
<td>Core Business Logic</td>
</tr>

<tr>
<td><strong>6</strong></td>
<td>Closures & Notifications</td>
<td>court_closures, notifications</td>
<td>2-3 days</td>
<td>Final Features</td>
</tr>
</table>

---

## 📖 Phase Documentation

### Phase 1: Authentication & User Management
**File**: [DB_PHASE_1_AUTHENTICATION.md](DB_PHASE_1_AUTHENTICATION.md)

**What You'll Build:**
- User registration and login
- Password encryption (bcrypt)
- User profiles with emergency contacts
- Global admin functionality
- Active/inactive status

**Tables**: `users`

**Key Features:**
- Email-based authentication
- Full name and contact info
- Emergency contact for safety
- Global admin bypass for developers

**Dependencies**: None - Start here!

---

### Phase 2: Venue Setup
**File**: [DB_PHASE_2_VENUES.md](DB_PHASE_2_VENUES.md)

**What You'll Build:**
- Venue registration and profiles
- Venue configuration settings
- Operating hours (7 days/week)
- Google Maps integration

**Tables**: `venues`, `venue_settings`, `venue_operating_hours`

**Key Features:**
- Single venue per owner (MVP)
- Configurable slot durations (min/max)
- Pakistan timezone and PKR currency defaults
- Different hours for each day of week

**Dependencies**: Phase 1 (users)

---

### Phase 3: Court Management
**File**: [DB_PHASE_3_COURTS.md](DB_PHASE_3_COURTS.md)

**What You'll Build:**
- Sport types (Badminton, Tennis, Basketball, etc.)
- Individual courts within venue
- Time-based pricing rules
- Peak/off-peak pricing

**Tables**: `court_types`, `courts`, `pricing_rules`

**Key Features:**
- Courts have unique names within venue
- Pricing varies by time and day
- Priority system for overlapping rules
- Active/inactive status for courts

**Dependencies**: Phase 2 (venues)

---

### Phase 4: Roles & Permissions
**File**: [DB_PHASE_4_ROLES.md](DB_PHASE_4_ROLES.md)

**What You'll Build:**
- System roles (Owner, Admin, Receptionist, Staff, Customer)
- Custom roles
- Granular permissions (action:resource format)
- User-role assignments

**Tables**: `roles`, `permissions`, `role_permissions`, `user_roles`

**Key Features:**
- Action-based permissions (create:bookings, read:reports, etc.)
- System roles cannot be deleted
- Custom roles can be created by owners
- Permission checking with user.can?(action, resource)

**Dependencies**: Phase 1 (users)

---

### Phase 5: Booking System
**File**: [DB_PHASE_5_BOOKINGS.md](DB_PHASE_5_BOOKINGS.md)

**What You'll Build:**
- Court bookings with time slots
- Double-booking prevention
- Payment tracking (cash for MVP)
- Booking status workflow
- Complete audit trail

**Tables**: `bookings`, `booking_logs`

**Key Features:**
- Auto-generated booking numbers (BK-YYYYMMDD-XXXX)
- Double-booking prevented (DB + app level)
- Dynamic price calculation from pricing rules
- Booking logs track all changes
- Status: confirmed → completed/cancelled/no_show

**Dependencies**: Phases 1-4

---

### Phase 6: Court Closures & Notifications
**File**: [DB_PHASE_6_CLOSURES_NOTIFICATIONS.md](DB_PHASE_6_CLOSURES_NOTIFICATIONS.md)

**What You'll Build:**
- Court maintenance scheduling
- In-app notifications
- Booking confirmations and reminders
- Venue announcements

**Tables**: `court_closures`, `notifications`

**Key Features:**
- Courts can be blocked for maintenance
- Closures prevent new bookings
- Automatic notifications on booking creation
- Read/unread status tracking
- Priority levels for notifications

**Dependencies**: Phases 1-5

---

## 🚀 Quick Start

### 1. Initialize Database

```bash
# Create database
rails db:create

# Run migrations phase by phase
rails db:migrate
```

### 2. Run Seeds in Order

```bash
# Phase 1
rails runner db/seeds/01_users.rb

# Phase 2
rails runner db/seeds/02_venues.rb

# Phase 3
rails runner db/seeds/03_courts.rb

# Phase 4
rails runner db/seeds/04_roles_permissions.rb

# Phase 5
rails runner db/seeds/05_bookings.rb

# Phase 6
rails runner db/seeds/06_closures_notifications.rb

# Or run all at once
rails db:seed
```

### 3. Verify Data

```bash
rails console

# Check user count
User.count
=> 5

# Check venue setup
Venue.first.venue_setting
Venue.first.venue_operating_hours.count
=> 7

# Check courts
Court.count
=> 6

# Check roles and permissions
Role.count
=> 5
Permission.count
=> 45

# Check bookings
Booking.upcoming.count
=> X

# Check notifications
Notification.unread.count
=> X
```

---

## 📊 Database Schema Summary

### Total Tables: 16

**User Management**:
- users

**Venue System**:
- venues
- venue_settings (1:1 with venues)
- venue_operating_hours (7 per venue)

**Court System**:
- court_types
- courts
- pricing_rules

**Access Control**:
- roles
- permissions
- role_permissions (join table)
- user_roles (join table)

**Booking System**:
- bookings
- booking_logs

**Operations**:
- court_closures
- notifications

---

## 🔑 Key Design Decisions

### 1. **Dynamic Time Slots**
❌ Not stored in database  
✅ Generated on-the-fly based on operating hours and settings  
**Why**: Maximum flexibility, no data bloat

### 2. **Single Venue (MVP)**
❌ Multi-venue support  
✅ One venue per owner  
**Why**: Simpler for MVP, can expand later

### 3. **Simplified Roles**
❌ `is_system_role` + `is_custom` (two booleans)  
✅ Only `is_custom` boolean  
**Why**: One boolean sufficient (false = system, true = custom)

### 4. **Pakistan Defaults**
- Timezone: `Asia/Karachi`
- Currency: `PKR`
- Phone format: `+92 XXX XXXXXXX`

### 5. **Payment Model**
- **MVP**: Cash only (payment_method, payment_status fields)
- **Future**: Online payments (Stripe/Razorpay/JazzCash)

### 6. **Notifications**
- **MVP**: In-app only
- **Future**: Email/SMS integration

---

## ✅ Testing Strategy

Each phase includes:

1. **Model Tests**
   - Validations
   - Associations
   - Scopes
   - Instance methods

2. **Integration Tests**
   - Database constraints
   - Foreign key relationships
   - Cascade deletes

3. **Seed Data Tests**
   - Data loads without errors
   - Expected counts match
   - Relationships established

Run tests after each phase:

```bash
# Run all specs
rspec

# Run specific model
rspec spec/models/user_spec.rb

# Run with coverage
COVERAGE=true rspec
```

---

## 🔒 Security Considerations

1. **Password Encryption**: Use bcrypt via `has_secure_password`
2. **SQL Injection**: Use ActiveRecord queries, avoid raw SQL
3. **Permission Checks**: Always check `user.can?(action, resource)`
4. **Global Admin**: Only for developers, not shown in UI
5. **Soft Deletes**: Consider adding `deleted_at` for sensitive data
6. **Audit Trail**: booking_logs tracks all changes with IP and user agent

---

## 🐛 Common Issues & Solutions

### Issue: Migration fails with foreign key error
**Solution**: Ensure dependent migrations run first. Check migration order.

### Issue: Seed data fails
**Solution**: Run seeds in order (01, 02, 03, etc.). Check dependencies.

### Issue: Double booking still happens
**Solution**: Add database-level unique index + app-level validation:
```ruby
add_index :bookings, [:court_id, :start_time, :end_time], unique: true
```

### Issue: Timezone issues
**Solution**: Always use `Time.current` or `Time.zone.now`, never `Time.now`

### Issue: Booking number not unique
**Solution**: Use database-level unique constraint + optimistic locking

---

## 📈 Performance Optimization

### Indexes Added
- All foreign keys
- Frequently queried fields (email, slug, status, is_active)
- Composite indexes for complex queries
- **Total indexes**: ~40

### Query Optimization
- Use `includes` for N+1 prevention
- Add `counter_cache` for counts
- Use database views for complex reports
- Pagination for large datasets

### Caching Strategy
- Fragment caching for court availability
- Redis for session storage
- Action caching for static pages

---

## 🔄 Migration Management

### Safe Migration Practices

```ruby
# ✅ Good: Reversible migration
def change
  add_column :users, :phone, :string
end

# ❌ Bad: Irreversible migration
def change
  User.update_all(is_active: true)
end

# ✅ Better: Separate up/down
def up
  add_column :users, :phone, :string
  User.update_all(is_active: true)
end

def down
  remove_column :users, :phone
end
```

### Rolling Back

```bash
# Rollback last migration
rails db:rollback

# Rollback specific version
rails db:migrate:down VERSION=20260407120000

# Rollback multiple steps
rails db:rollback STEP=3

# Reset and reseed (development only!)
rails db:reset
```

---

## 📝 Next Steps After Database Setup

1. **API Development** (1-2 weeks)
   - RESTful endpoints for all resources
   - JWT authentication
   - API documentation (Swagger/OpenAPI)
   - Rate limiting

2. **Background Jobs** (3-5 days)
   - Booking reminders (Sidekiq)
   - Email notifications (ActionMailer)
   - SMS notifications (Twilio)
   - Report generation

3. **Frontend Integration** (2-3 weeks)
   - Angular app connection
   - Real-time updates (ActionCable)
   - Calendar view for bookings
   - Admin dashboard

4. **Testing & QA** (1 week)
   - Integration tests
   - E2E tests (Cypress/Playwright)
   - Load testing
   - Security audit

5. **Deployment** (3-5 days)
   - Kamal setup
   - Production database migration
   - Environment variables
   - SSL certificates
   - Monitoring (Sentry, New Relic)

---

## 📚 Additional Resources

- **Main Schema**: [SCHEMA.md](SCHEMA.md)
- **API Documentation**: [API_DOCS.md](API_DOCS.md) _(to be created)_
- **Deployment Guide**: [KAMAL_DEPLOYMENT.md](KAMAL_DEPLOYMENT.md)
- **Testing Guide**: [spec/TESTING.md](../spec/TESTING.md)

---

## 🤝 Contributing

When working on database changes:

1. Create feature branch
2. Write migration
3. Update models and associations
4. Add tests
5. Update seed data
6. Update documentation
7. Create pull request

---

## 📞 Support

For questions or issues:
- Check phase documentation first
- Review [SCHEMA.md](SCHEMA.md) for table details
- Check existing tests for examples

---

**Good luck with your implementation! 🚀**

Remember: Build incrementally, test thoroughly, and don't skip phases!

---

*Last Updated: 2026-04-07*  
*Version: 1.0 (MVP)*
