# Database Schema Design - Bookturf

## Overview
A flexible sports court booking management system supporting multiple venues, dynamic time slots, role-based access control with custom permissions.

---

## Design Decisions

### Time Slots Strategy
**Decision**: Dynamic slot generation (NOT stored in database)
- Store only `minimum_slot_duration` and `maximum_slot_duration` in venue settings
- Backend generates available slots on-the-fly based on:
  - Venue operating hours
  - Existing bookings
  - Court availability
  - Configured min/max durations
- **Benefits**: Eliminates data bloat, maximum flexibility, easy to adjust durations

### Multi-Tenancy Model
- Support multiple venues per owner
- Users can be assigned roles across multiple venues (configurable)
- Each venue operates independently with its own settings

### Permission System
- Action-based permissions: `create`, `read`, `update`, `delete` on specific resources
- Resources: `bookings`, `courts`, `venues`, `users`, `reports`, `settings`, `roles`
- Examples: `create:bookings`, `update:courts`, `delete:users`, `read:reports`
- Permissions are assigned to roles, roles are assigned to users per venue

### Payment Model
- **Phase 1** (Current): Cash payment at venue - no payment gateway integration
- **Phase 2** (Future): Online payments, partial payments, deposits
- Store payment method and amount in bookings table for future extensibility

---

## Core Tables

### 1. users
Primary user table for all system users.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| email | string | unique, not null, indexed | User email (login) |
| encrypted_password | string | not null | Encrypted password |
| first_name | string | not null | User's first name |
| last_name | string | not null | User's last name |
| phone_number | string | indexed | Contact number |
| emergency_contact_name | string | | Emergency contact person name |
| emergency_contact_phone | string | | Emergency contact phone number |
| is_global_admin | boolean | default: false | Developer/super admin flag |
| is_active | boolean | default: true | Account active status |
| created_at | datetime | not null | Record creation timestamp |
| updated_at | datetime | not null | Record update timestamp |

**Indexes**: 
- `email` (unique)
- `phone_number`
- `is_global_admin`

**Notes**:
- `is_global_admin` bypasses all permission checks (for developers)
- Global admins don't need roles/permissions in the app
- Emergency contact info for safety and liability purposes

---

### 2. venues
Represents sports facilities/arenas.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| owner_id | bigint | FK → users, not null, indexed | Venue owner |
| name | string | not null | Venue name |
| slug | string | unique, indexed | URL-friendly identifier |
| description | text | | Venue description |
| address | text | not null | Physical address |
| city | string | indexed | City |
| state | string | indexed | State/Province |
| country | string | indexed | Country |
| postal_code | string | | Postal/ZIP code |
| latitude | decimal(10,8) | | GPS latitude |
| longitude | decimal(11,8) | | GPS longitude |
| phone_number | string | | Venue contact |
| email | string | | Venue email |
| is_active | boolean | default: true | Venue operational status |
| average_rating | decimal(3,2) | default: 0.0 | Cached average rating (0-5) |
| total_reviews | integer | default: 0 | Total number of reviews |
| created_at | datetime | not null | Record creation timestamp |
| updated_at | datetime | not null | Record update timestamp |

**Indexes**:
- `owner_id`
- `slug` (unique)
- `city`, `state`, `country`
- `is_active`
- `average_rating` (for sorting venues by rating)

**Notes**:
- `average_rating` and `total_reviews` are cached/calculated from venue_reviews table
- Update these counters after review creation/update/deletion via callback or background job

---

### 3. venue_settings
Configuration settings per venue (operating hours, slot durations, policies).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| venue_id | bigint | FK → venues, unique, not null | One setting per venue |
| minimum_slot_duration | integer | not null, default: 60 | Min booking duration (minutes) |
| maximum_slot_duration | integer | not null, default: 180 | Max booking duration (minutes) |
| slot_interval | integer | not null, default: 30 | Slot generation interval (minutes) |
| advance_booking_days | integer | default: 30 | How far ahead users can book |
| timezone | string | not null, default: 'UTC' | Venue timezone |
| currency | string | default: 'USD' | Currency code |
| requires_approval | boolean | default: false | Booking needs approval |
| cancellation_hours | integer | | Hours before booking to allow cancellation |
| created_at | datetime | not null | Record creation timestamp |
| updated_at | datetime | not null | Record update timestamp |

**Indexes**:
- `venue_id` (unique)

**Notes**:
- `slot_interval`: The granularity for generating time slots (e.g., 30min means slots start at :00 and :30)
- `advance_booking_days`: Limits how far in advance bookings can be made

---

### 4. venue_operating_hours
Daily operating hours for each venue.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| venue_id | bigint | FK → venues, not null, indexed | Venue reference |
| day_of_week | integer | not null (0-6) | 0=Sunday, 6=Saturday |
| opens_at | time | not null | Opening time |
| closes_at | time | not null | Closing time |
| is_closed | boolean | default: false | Venue closed on this day |
| created_at | datetime | not null | Record creation timestamp |
| updated_at | datetime | not null | Record update timestamp |

**Indexes**:
- `venue_id, day_of_week` (composite unique)

**Notes**:
- If `is_closed` is true, venue doesn't operate on that day
- Slots are generated between `opens_at` and `closes_at`

---

### 5. court_types
Generic sport types (Tennis, Basketball, Badminton, etc.).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| name | string | unique, not null | Court type name (e.g., "Tennis") |
| slug | string | unique, indexed | URL-friendly identifier |
| description | text | | Type description |
| icon | string | | Icon identifier/URL |
| created_at | datetime | not null | Record creation timestamp |
| updated_at | datetime | not null | Record update timestamp |

**Indexes**:
- `name` (unique)
- `slug` (unique)

**Notes**:
- Global/shared across all venues
- Examples: Tennis, Basketball, Badminton, Squash, Volleyball, Futsal, etc.

---

### 6. courts
Individual courts/playing areas within a venue.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| venue_id | bigint | FK → venues, not null, indexed | Parent venue |
| court_type_id | bigint | FK → court_types, not null, indexed | Type of court |
| name | string | not null | Court identifier (e.g., "Court 1") |
| description | text | | Court details |
| is_active | boolean | default: true | Court availability status |
| display_order | integer | default: 0 | Sort order in listings |
| created_at | datetime | not null | Record creation timestamp |
| updated_at | datetime | not null | Record update timestamp |

**Indexes**:
- `venue_id, name` (composite unique - unique within venue)
- `court_type_id`
- `is_active`

---

### 7. pricing_rules
Flexible pricing per court type, time-based (peak/off-peak).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| venue_id | bigint | FK → venues, not null, indexed | Venue reference |
| court_type_id | bigint | FK → court_types, not null, indexed | Court type |
| name | string | not null | Rule name (e.g., "Peak Hours") |
| price_per_hour | decimal(10,2) | not null | Hourly rate |
| day_of_week | integer | | Specific day (0-6), null = all days |
| start_time | time | | Rule start time |
| end_time | time | | Rule end time |
| start_date | date | | Rule validity start |
| end_date | date | | Rule validity end |
| priority | integer | default: 0 | Higher priority wins on conflicts |
| is_active | boolean | default: true | Rule enabled/disabled |
| created_at | datetime | not null | Record creation timestamp |
| updated_at | datetime | not null | Record update timestamp |

**Indexes**:
- `venue_id, court_type_id` (composite)
- `is_active`
- `priority`

**Notes**:
- Multiple rules can exist; highest `priority` wins when overlapping
- `null` values for day/time mean "apply to all"
- Examples:
  - Peak hours: Mon-Fri 6PM-10PM = $50/hr
  - Off-peak: Mon-Fri 10AM-6PM = $30/hr
  - Weekend: Sat-Sun all day = $60/hr

---

## User Management & Permissions

### 8. roles
Predefined and custom roles.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| name | string | unique, not null, indexed | Role name |
| slug | string | unique, indexed | URL-friendly identifier |
| description | text | | Role description |
| is_system_role | boolean | default: false | System-defined (can't be deleted) |
| is_custom | boolean | default: false | Custom role created by owner/admin |
| created_at | datetime | not null | Record creation timestamp |
| updated_at | datetime | not null | Record update timestamp |

**Indexes**:
- `name` (unique)
- `slug` (unique)
- `is_system_role`

**System Roles** (is_system_role = true):
1. **owner** - Full control of their venues
2. **admin** - Most permissions (venue management, user management)
3. **receptionist** - Manage bookings, view schedules, check-ins
4. **staff** - Basic operations (view bookings, assist customers)
5. **customer** - Regular user who books courts

**Notes**:
- System roles cannot be deleted
- Custom roles can be created by owners/admins per venue
- `is_custom` flag helps filter and identify user-created roles

---

### 9. permissions
Granular action-based permissions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| resource | string | not null, indexed | Resource name |
| action | string | not null, indexed | Action type |
| name | string | unique, not null | Combined name (e.g., "create:bookings") |
| description | text | | Human-readable description |
| created_at | datetime | not null | Record creation timestamp |
| updated_at | datetime | not null | Record update timestamp |

**Indexes**:
- `resource, action` (composite unique)
- `name` (unique)

**Resources**:
- `bookings`
- `courts`
- `venues`
- `users`
- `roles`
- `reports`
- `settings`
- `pricing`
- `closures` (court closures/maintenance)
- `reviews`
- `notifications`

**Actions**:
- `create`
- `read`
- `update`
- `delete`
- `manage` (all CRUD operations)

**Permission Examples**:
- `create:bookings` - Can create bookings
- `read:reports` - Can view reports
- `update:settings` - Can modify venue settings
- `delete:users` - Can delete users
- `manage:courts` - Full CRUD on courts

---

### 10. role_permissions
Join table: roles ↔ permissions (many-to-many).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| role_id | bigint | FK → roles, not null, indexed | Role reference |
| permission_id | bigint | FK → permissions, not null, indexed | Permission reference |
| created_at | datetime | not null | Record creation timestamp |

**Indexes**:
- `role_id, permission_id` (composite unique)

---

### 11. user_venue_roles
Join table: users ↔ venues ↔ roles (many-to-many-to-many).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| user_id | bigint | FK → users, not null, indexed | User reference |
| venue_id | bigint | FK → venues, not null, indexed | Venue reference |
| role_id | bigint | FK → roles, not null, indexed | Role reference |
| assigned_by | bigint | FK → users | Who assigned this role |
| assigned_at | datetime | not null | When role was assigned |
| created_at | datetime | not null | Record creation timestamp |
| updated_at | datetime | not null | Record update timestamp |

**Indexes**:
- `user_id, venue_id, role_id` (composite unique)
- `user_id, venue_id` (composite)
- `venue_id, role_id` (composite)

**Notes**:
- A user can have multiple roles across different venues
- A user can also have multiple roles within the same venue (flexibility)
- `assigned_by` tracks who granted the role (audit trail)

---

## Booking System

### 12. bookings
Core booking records.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| booking_number | string | unique, not null, indexed | Human-readable booking ID |
| user_id | bigint | FK → users, not null, indexed | Customer who booked |
| court_id | bigint | FK → courts, not null, indexed | Booked court |
| venue_id | bigint | FK → venues, not null, indexed | Venue (denormalized for queries) |
| start_time | datetime | not null, indexed | Booking start (timestamp) |
| end_time | datetime | not null, indexed | Booking end (timestamp) |
| duration_minutes | integer | not null | Booking duration |
| status | string | not null, indexed | confirmed, completed, cancelled, no_show |
| total_amount | decimal(10,2) | default: 0 | Total booking cost |
| payment_method | string | | cash, online, card (future) |
| payment_status | string | default: 'pending' | pending, paid, refunded |
| paid_amount | decimal(10,2) | default: 0 | Amount paid (for partial payments) |
| notes | text | | Customer/admin notes |
| cancelled_at | datetime | | Cancellation timestamp |
| cancelled_by | bigint | FK → users | Who cancelled |
| cancellation_reason | text | | Cancellation reason |
| checked_in_at | datetime | | Check-in timestamp |
| checked_in_by | bigint | FK → users | Receptionist who checked in |
| created_by | bigint | FK → users | Who created booking (admin/receptionist) |
| created_at | datetime | not null | Record creation timestamp |
| updated_at | datetime | not null | Record update timestamp |

**Indexes**:
- `booking_number` (unique)
- `user_id`
- `court_id, start_time, end_time` (composite - prevent double booking)
- `venue_id, start_time` (composite)
- `status`
- `start_time, end_time` (composite)

**Status Values**:
- `confirmed` - Booking is active
- `completed` - User showed up and played
- `cancelled` - Booking was cancelled
- `no_show` - User didn't show up

**Notes**:
- `booking_number` format: `BK-{venue_code}-{YYYYMMDD}-{sequential}` (e.g., "BK-NYC01-20260406-001")
- `created_by` vs `user_id`: 
  - `user_id` is the customer
  - `created_by` is who created it (could be receptionist on behalf of customer)
- Prevent overlapping bookings via application logic + DB constraint

---

### 13. booking_logs
Audit trail for booking changes.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| booking_id | bigint | FK → bookings, not null, indexed | Booking reference |
| user_id | bigint | FK → users, indexed | Who made the change |
| action | string | not null | created, updated, cancelled, checked_in, completed |
| changes | jsonb | | JSON of field changes (before/after) |
| ip_address | string | | IP address of user |
| user_agent | text | | Browser/device info |
| created_at | datetime | not null | When action occurred |

**Indexes**:
- `booking_id`
- `user_id`
- `created_at`

**Notes**:
- Tracks all changes to bookings for audit/compliance
- `changes` stores JSON: `{"field": {"from": "old_value", "to": "new_value"}}`

---

### 14. court_closures
Block courts for maintenance, special events, or other reasons.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| court_id | bigint | FK → courts, not null, indexed | Court being blocked |
| venue_id | bigint | FK → venues, not null, indexed | Venue (denormalized for queries) |
| title | string | not null | Closure title (e.g., "Maintenance") |
| description | text | | Detailed reason for closure |
| start_time | datetime | not null, indexed | Closure start |
| end_time | datetime | not null, indexed | Closure end |
| is_recurring | boolean | default: false | Whether this repeats |
| recurrence_rule | string | | RRULE format for recurring closures |
| created_by | bigint | FK → users | Who created this closure |
| created_at | datetime | not null | Record creation timestamp |
| updated_at | datetime | not null | Record update timestamp |

**Indexes**:
- `court_id, start_time, end_time` (composite)
- `venue_id, start_time` (composite)
- `start_time, end_time` (composite)

**Notes**:
- Blocks bookings for specified time periods
- Visible to users when viewing availability (shows as "Maintenance" or custom title)
- `recurrence_rule` uses iCalendar RRULE format for recurring closures (e.g., "Every Monday 6-8 AM for cleaning")
- Application logic checks closures when generating available time slots

---

### 15. notifications
System notifications and alerts for users.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| user_id | bigint | FK → users, not null, indexed | Notification recipient |
| venue_id | bigint | FK → venues, indexed | Related venue (optional) |
| booking_id | bigint | FK → bookings, indexed | Related booking (optional) |
| type | string | not null, indexed | Notification type (see below) |
| title | string | not null | Notification title |
| message | text | not null | Notification body |
| action_url | string | | Link to related resource |
| is_read | boolean | default: false, indexed | Read status |
| read_at | datetime | | When user read it |
| priority | string | default: 'normal' | low, normal, high, urgent |
| sent_at | datetime | | When notification was sent |
| created_at | datetime | not null | Record creation timestamp |

**Indexes**:
- `user_id, is_read` (composite)
- `user_id, created_at` (composite - for inbox)
- `type`
- `priority`

**Notification Types**:
- `booking_confirmed` - Booking created
- `booking_reminder` - Upcoming booking (1 hour, 1 day before)
- `booking_cancelled` - Booking cancelled
- `booking_modified` - Booking time/court changed
- `court_closure` - Court closed during user's usual booking time
- `payment_due` - Payment reminder (future)
- `venue_announcement` - Venue-wide announcements
- `system_alert` - System-level messages

**Notes**:
- Can be displayed in-app, sent via email, or push notifications
- `priority` helps UI styling (colors, badges)
- `read_at` tracks engagement

---

### 16. venue_reviews
User ratings and reviews for venues.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| venue_id | bigint | FK → venues, not null, indexed | Venue being reviewed |
| user_id | bigint | FK → users, not null, indexed | Reviewer |
| booking_id | bigint | FK → bookings, indexed | Related booking (proof of visit) |
| rating | integer | not null, 1-5 | Star rating (1-5) |
| title | string | | Review title |
| comment | text | | Review text |
| is_published | boolean | default: true | Visible to public |
| response | text | | Venue owner response |
| responded_by | bigint | FK → users | Who responded |
| responded_at | datetime | | Response timestamp |
| helpful_count | integer | default: 0 | Number of "helpful" votes |
| created_at | datetime | not null | Record creation timestamp |
| updated_at | datetime | not null | Record update timestamp |

**Indexes**:
- `venue_id, is_published` (composite)
- `user_id`
- `booking_id`
- `rating`
- `created_at`

**Check Constraints**:
- `rating BETWEEN 1 AND 5`

**Notes**:
- Users can only review after a completed booking
- One review per booking (prevent spam)
- Venue owners/admins can respond to reviews
- Average rating calculated on-the-fly or cached on venues table
- `is_published` allows moderation (hide offensive reviews)

---

## Optional/Future Tables

### 17. memberships (Future)
For recurring memberships and reserved slots.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| user_id | bigint | FK → users, not null | Member |
| venue_id | bigint | FK → venues, not null | Venue |
| membership_plan_id | bigint | FK → membership_plans | Plan details |
| starts_at | date | not null | Membership start |
| ends_at | date | not null | Membership end |
| status | string | not null | active, expired, cancelled |
| created_at | datetime | not null | Record creation timestamp |
| updated_at | datetime | not null | Record update timestamp |

**Note**: Schema placeholder for future implementation.

---

### 18. equipment_rentals (Future)
Track equipment rented during bookings.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| booking_id | bigint | FK → bookings, not null | Associated booking |
| equipment_id | bigint | FK → equipment | Equipment item |
| quantity | integer | not null | Number rented |
| rental_fee | decimal(10,2) | | Rental cost |
| created_at | datetime | not null | Record creation timestamp |
| updated_at | datetime | not null | Record update timestamp |

**Note**: Schema placeholder for future implementation.

---

### 19. discounts_coupons (Future)
Promotional codes and discounts.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| venue_id | bigint | FK → venues | Venue-specific or global (null) |
| code | string | unique, not null | Coupon code |
| description | text | | Discount description |
| discount_type | string | | percentage, fixed_amount |
| discount_value | decimal(10,2) | | Discount value |
| max_uses | integer | | Maximum redemptions |
| used_count | integer | default: 0 | Times used |
| valid_from | datetime | | Start date |
| valid_until | datetime | | Expiration date |
| is_active | boolean | default: true | Enabled status |
| created_at | datetime | not null | Record creation timestamp |
| updated_at | datetime | not null | Record update timestamp |

**Note**: Schema placeholder for future implementation.

---

## Database Constraints & Validations

### Unique Constraints
- `users.email`
- `venues.slug`
- `court_types.name`, `court_types.slug`
- `courts(venue_id, name)` - Court name unique per venue
- `roles.name`, `roles.slug`
- `permissions.name`, `permissions(resource, action)`
- `role_permissions(role_id, permission_id)`
- `user_venue_roles(user_id, venue_id, role_id)`
- `bookings.booking_number`
- `venue_settings.venue_id`
- `venue_operating_hours(venue_id, day_of_week)`
- `venue_reviews(booking_id)` - One review per booking

### Check Constraints
- `venue_settings.minimum_slot_duration > 0`
- `venue_settings.maximum_slot_duration >= minimum_slot_duration`
- `venue_settings.slot_interval > 0`
- `bookings.end_time > start_time`
- `bookings.duration_minutes > 0`
- `bookings.paid_amount >= 0`
- `bookings.paid_amount <= total_amount`
- `pricing_rules.price_per_hour >= 0`
- `pricing_rules.end_time > start_time` (when both set)
- `venue_operating_hours.closes_at > opens_at`
- `venue_operating_hours.day_of_week BETWEEN 0 AND 6`
- `court_closures.end_time > start_time`
- `venue_reviews.rating BETWEEN 1 AND 5`

### Foreign Key Constraints
All `FK →` references in tables above should have:
- `ON DELETE RESTRICT` (default) - Most cases
- `ON DELETE CASCADE` - For dependent data:
  - `venue_settings → venues`
  - `venue_operating_hours → venues`
  - `courts → venues`
  - `pricing_rules → venues`
  - `role_permissions → roles, permissions`
  - `user_venue_roles → users, venues, roles`
  - `booking_logs → bookings`
  - `court_closures → courts, venues`
  - `notifications → users` (SET NULL for venue, booking if deleted)
  - `venue_reviews → venues, users, bookings`

---

## Indexing Strategy

### High-Priority Indexes (Query Performance)
1. **Users**: `email`, `is_global_admin`, `phone_number`
2. **Venues**: `owner_id`, `slug`, `city`, `is_active`
3. **Courts**: `(venue_id, name)`, `court_type_id`, `is_active`
4. **Bookings**: 
   - `(court_id, start_time, end_time)` - Prevent double booking, check availability
   - `(venue_id, start_time)` - Venue schedule queries
   - `user_id` - User's bookings
   - `status` - Filter by status
   - `booking_number` - Quick lookup
5. **User Venue Roles**: 
   - `(user_id, venue_id, role_id)` - Permission checks
   - `(user_id, venue_id)` - User access to venues
6. **Role Permissions**: `(role_id, permission_id)` - Permission lookups
7. **Pricing Rules**: `(venue_id, court_type_id)`, `is_active`, `priority`
8. **Court Closures**: 
   - `(court_id, start_time, end_time)` - Check if court is blocked
   - `(venue_id, start_time)` - Venue-wide closures
9. **Notifications**: 
   - `(user_id, is_read)` - Unread notifications
   - `(user_id, created_at)` - Notification inbox
   - `type` - Filter by notification type
10. **Venue Reviews**: 
    - `(venue_id, is_published)` - Published reviews for venue
    - `rating` - Filter by rating
    - `booking_id` - Prevent duplicate reviews

### Composite Indexes Rationale
- `(court_id, start_time, end_time)`: Critical for availability checks and preventing double bookings
- `(venue_id, start_time)`: Efficient venue-wide schedule queries
- `(user_id, venue_id)`: Fast role/permission checks per venue
- `(venue_id, name)`: Unique court names per venue, sorted listings
- `(user_id, is_read)`: Fast unread notification queries

---

## Data Seeding Requirements

### Essential Seed Data

#### 1. Court Types
```
- Tennis
- Basketball  
- Badminton
- Squash
- Volleyball
- Futsal
- Pickleball
- Table Tennis
```

#### 2. System Roles
```
owner: Full control of venues
admin: Venue management, most permissions
receptionist: Booking management, check-ins
staff: Basic operations, customer assistance
customer: End user, booking only
```

#### 3. Permissions (Examples)
```
Bookings: create:bookings, read:bookings, update:bookings, delete:bookings, manage:bookings
Courts: create:courts, read:courts, update:courts, delete:courts
Venues: read:venues, update:venues, manage:venues
Users: create:users, read:users, update:users, delete:users
Roles: create:roles, read:roles, update:roles, delete:roles
Reports: read:reports, manage:reports
Settings: read:settings, update:settings
Pricing: create:pricing, read:pricing, update:pricing, delete:pricing
Closures: create:closures, read:closures, update:closures, delete:closures
Reviews: read:reviews, update:reviews (respond), delete:reviews (moderate)
Notifications: read:notifications, create:notifications (send announcements)
```

#### 4. Default Role-Permission Mappings

**Owner**:
- All permissions (manage:*)

**Admin**:
- All permissions except:
  - delete:venues
  - Full role management (only read:roles)

**Receptionist**:
- manage:bookings
- read:courts
- create:closures, read:closures (schedule maintenance)
- read:users
- read:reports (booking reports)
- read:settings
- read:notifications
- read:reviews, update:reviews (respond to reviews)

**Staff**:
- read:bookings
- read:courts
- read:users
- read:closures
- read:notifications

**Customer**:
- create:bookings (own)
- read:bookings (own)
- update:bookings (own - for cancellation)
- read:courts
- read:notifications (own)
- create:reviews (after completed booking)

---

## Technical Implementation Notes

### Time Slot Generation Algorithm
```
Input: venue_id, court_id, date
Output: Available time slots

1. Get venue settings (min/max duration, slot_interval)
2. Get operating hours for the day_of_week
3. If venue is_closed, return empty array
4. Check court_closures for this court on this date
   - Exclude blocked time ranges from available slots
5. Generate slots from opens_at to closes_at with slot_interval
6. For each slot:
   - Check if court is booked during that time
   - Check if court is closed during that time
   - If available, calculate pricing based on pricing_rules
   - Add to available_slots array
7. Return available_slots with {start_time, end_time, price, blocked_reason (if applicable)}
```

### Double Booking Prevention
- Database constraint: Unique index on `(court_id, start_time, end_time)`
- Application-level check: Query existing bookings before insert
- Transaction lock: Use row-level locks during booking creation

### Permission Check Flow
```
1. If user.is_global_admin? → Grant access
2. Get user's roles for the venue (user_venue_roles)
3. Get permissions for those roles (role_permissions)
4. Check if required permission exists
5. Grant/Deny access
```

### Multi-Venue Access
When a user has roles in multiple venues:
```ruby
# Get all venues user has access to
user.venues # Through user_venue_roles

# Get user's roles for specific venue
user.roles_for_venue(venue_id)

# Check permission for specific venue
user.can?(:create, :bookings, venue_id)
```

---

## Schema Migration Order

When implementing, create migrations in this sequence:

1. **Core User & Auth**
   - users

2. **Venue Foundation**
   - venues
   - venue_settings
   - venue_operating_hours

3. **Court System**
   - court_types
   - courts
   - pricing_rules
   - court_closures

4. **Permissions & Roles**
   - roles
   - permissions
   - role_permissions
   - user_venue_roles

5. **Booking System**
   - bookings
   - booking_logs

6. **User Engagement**
   - notifications
   - venue_reviews

7. **Future Enhancements**
   - memberships
   - equipment_rentals
   - discounts_coupons

---

## Schema Flexibility Points

The schema is designed to be extensible:

1. **Add new resources**: Simply create new permissions with resource name
2. **Custom roles**: `is_custom` flag allows venue-specific roles
3. **Dynamic pricing**: Multiple pricing rules with priority system
4. **Time slots**: No hardcoded slots, dynamically generated
5. **Payment methods**: `payment_method` and `payment_status` ready for future gateway integration
6. **Cancellation policies**: `cancellation_hours` in venue_settings, tracking in bookings
7. **Multi-venue scaling**: Separate data per venue, efficient querying with indexes
8. **Audit trail**: booking_logs tracks all changes
9. **Geographic search**: latitude/longitude ready for location-based queries
10. **Court maintenance**: Flexible court_closures with recurring patterns support
11. **Notifications**: Extensible notification types for various alerts and reminders
12. **Reviews**: Support for venue/court ratings, responses, and moderation
13. **Emergency contacts**: User safety and liability protection
14. **Future payments**: Schema ready for deposits, partial payments, refunds

---

## Final Confirmation Checklist

Before implementation, please confirm:

1. ✅ **Guest bookings**: Not supported - users must register
2. ✅ **Court maintenance**: Yes - court_closures table with name/description
3. ✅ **Notifications**: Yes - notifications table for alerts and reminders
4. ✅ **Reviews**: Yes - venue_reviews table with ratings and responses
5. ✅ **Emergency contacts**: Yes - added to users table
6. ⏸️ **Memberships**: Future feature - placeholder in schema
7. ⏸️ **Payments**: Cash only for now - online payments in future
8. ⏸️ **Recurring bookings**: Future feature - not in initial schema

### Additional Questions (Optional)
- **Booking number format**: Is `BK-{venue_code}-{YYYYMMDD}-{sequential}` acceptable?
- **Average rating cache**: Should we cache average rating on venues table for performance?
- **Review moderation**: Should reviews require approval before being published?
- **Notification channels**: In-app only, or also email/SMS/push?
- **Court images**: Should courts have a photos/gallery table?
- **Venue amenities**: Need a separate table for amenities (parking, WiFi, lockers, etc.)?

---

## Next Steps

1. **Review & Confirm**: Review this schema design and confirm all requirements are met
2. **Refinement**: Answer questions above to finalize schema
3. **Implementation**:
   - Create Rails migrations
   - Setup models with associations
   - Implement validation rules
   - Create seed data
   - Setup permission system (CanCanCan or Pundit)
   - Build time slot generation service
   - Implement booking service with double-booking prevention

---

*Last Updated: 2026-04-06*
*Status: Draft - Awaiting Review*
