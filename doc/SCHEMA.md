# Database Schema Design - Bookturf

## Overview
A flexible sports court booking management system for **single venue** with dynamic time slots, role-based access control with custom permissions.

**MVP Scope**: Single venue per owner. Multi-venue support planned for future phase.

---

## Design Decisions

### Time Slots Strategy
**Decision**: Dynamic slot generation (NOT stored in database)
- Store only `minimum_slot_duration`, `maximum_slot_duration`, and `slot_interval` in venue settings
- Backend generates available slots on-the-fly based on:
  - Venue operating hours
  - Existing bookings
  - Court availability
  - Configured min/max durations and slot intervals
- **Benefits**: Eliminates data bloat, maximum flexibility, easy to adjust durations

**How Slot Durations Work:**
- **minimum_slot_duration** (e.g., 60 minutes): Users cannot book less than this duration
- **maximum_slot_duration** (e.g., 180 minutes): Users cannot book more than this duration  
- **slot_interval** (e.g., 30 minutes): Time increments for generating slots
  - Example: If venue opens at 9:00 AM with 30-min intervals, slots are: 9:00, 9:30, 10:00, 10:30...
  - User can book: 9:00-10:00 (60 min) or 9:30-11:30 (120 min) or 10:00-1:00 PM (180 min)

### Single Venue Model (MVP)
- One venue per owner
- All users (owner, staff, customers) operate within this single venue
- Venue settings, operating hours, courts, and pricing all belong to one venue
- **Future**: Multi-venue support with cross-venue role assignments

### Permission System
- Action-based permissions: `create`, `read`, `update`, `delete` on specific resources
- Resources: `bookings`, `courts`, `venues`, `users`, `reports`, `settings`, `roles`
- Examples: `create:bookings`, `update:courts`, `delete:users`, `read:reports`
- Permissions are assigned to roles, roles are assigned to users per venue

### Payment Model
- **MVP** (Current): Cash payment at venue - no payment gateway integration
- **Future**: Online payments, partial payments, deposits
- Store payment method and amount in bookings table for future extensibility

### Google Maps Integration
- Store `latitude` and `longitude` in venues table
- Google Maps link is generated dynamically: `https://www.google.com/maps?q={latitude},{longitude}`
- **Benefits**: Can use coordinates for distance calculations, multiple map providers, location-based features

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
| latitude | decimal(10,8) | | GPS latitude (for maps & distance calculations) |
| longitude | decimal(11,8) | | GPS longitude (for maps & distance calculations) |
| phone_number | string | | Venue contact |
| email | string | | Venue email |
| is_active | boolean | default: true | Venue operational status |
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
**Google Maps Link**: Generated from lat/long: `https://www.google.com/maps?q={latitude},{longitude}`
- Latitude/longitude also enable future features: distance calculations, location-based search, etc.
- For MVP: Single venue, so owner_id is straightforward one-to-one relationship

### 3. venue_settings
Configuration settings per venue (operating hours, slot durations, policies).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| venue_id | bigint | FK → venues, unique, not null | One setting per venue |
| minimum_slot_duration | integer | not null, default: 60 | Min booking duration (minutes) |
| maximum_slot_duration | integer | not null, default: 180 | Max booking duration (minutes) |
| slot_interval | integer | not null, default: 30 | Slot generation interval (minutes) |
| advance_booking_days | integer | defaultAsia/Karachi' | Venue timezone (Pakistan Time) |
| currency | string | default: 'PKR' | Currency code (Pakistani Rupee)ue timezone |
| currency | string | default: 'USD' | Currency code |
| requires_approval | boolean | default: false | Booking needs approval |
| cancellation_hours | integer | | Hours before booking to allow cancellation |
| created_at | datetime | not null | Record creation timestamp |
| updated_at | datetime | not null | Record update timestamp |

**Indexes**:
- `venue_id` (unique)

****Slot Duration Examples**:
  - `minimum_slot_duration = 60`: Users must book at least 1 hour
  - `maximum_slot_duration = 180`: Users can book up to 3 hours per booking
  - `slot_interval = 30`: Slots start every 30 minutes (9:00, 9:30, 10:00, 10:30...)
- `advance_booking_days`: Limits how far in advance bookings can be made
- **Why separate table?** Even for single venue, keeps configuration values separate from venue identity data
- **Future**: When expanding to multiple venues, just add more rows herin means slots start at :00 and :30)
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
- **Why separate table?** Stores 7 rows (one per day of week) with different times - better normalized than 7 columns in settings
- **Example**: Monday opens 9 AM-11 PM, but Sunday opens 10 AM-8 PM - each day can have unique hours
- `venue_id, day_of_week` (composite unique)

Sport types offered at the venue (Tennis, Basketball, Badminton, etc.).

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
- **court_types = Sports Types** (Tennis, Basketball, Badminton, Squash, Volleyball, Futsal, etc.)
- Each court in your venue links to a court_type to specify what sport it's for
- **Example**: "Court 1" → Basketball, "Court 2" → Badminton, "Court 3" → Tennis
- For MVP: Global types (not venue-specific). Future: venue-specific types if needed
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

**Pricing Rules Example (Pakistani Rupees):**

Your badminton courts have time-based pricing:
```
Rule 1: Weekday Morning (Mon-Fri, 6 AM-12 PM) = 1500 PKR/hour
Rule 2: Weekday Evening (Mon-Fri, 6 PM-11 PM) = 2500 PKR/hour (peak)
Rule 3: Weekend All Day (Sat-Sun) = 2000 PKR/hour
```

When user books:
- **Friday at 7 PM** → Matches "Weekday Evening" → Charges **2500 PKR/hour**
- **Saturday at 10 AM** → Matches "Weekend All Day" → Charges **2000 PKR/hour**
- **Tuesday at 8 AM** → Matches "Weekday Morning" → Charges **1500 PKR/hour**

If multiple rules match the same time, the one with highest `priority` value wins.
- `priority`

**Notcustom | boolean | default: false | Custom role (true) or System role (false)
- `null` values for day/time mean "apply to all"
- Examples:
  - Peak hours: Mon-Fri 6PM-10PM = $50/hr
  - Off-peak: Mon-Fri 10AM-6PM = $30/hr
  - Weekend: Sat-Sun all day = $60/hr

---

## User Management & Permissions

### 8. roles
Predefined and custom roles.
custom`

**System Roles** (is_custom = false):
1. **owner** - Full control of the venue (the person who created it)
2. **admin** - Most permissions (venue management, user management, reports)
3. **receptionist** - Manage bookings, view schedules, check-ins, assist customers
4. **staff** - Basic operations (view bookings, assist customers)
5. **customer** - Regular user who books courts

**Custom Roles** (is_custom = true):
- Venue owner can create custom roles with specific permissions
- Example: "Senior Receptionist" role with additional report access

**Notes**:
- **Simplified from original**: Removed `is_system_role` boolean (redundant with `is_custom`)
- System roles cannot be deleted
- `is_custom = false` → System role | `is_custom = true` → Custom role
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
- `manage:couroles
Join table: users ↔ roles (many-to-many). Tracks all staff and customers in the venue.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK, auto | Primary key |
| user_id | bigint | FK → users, not null, indexed | User reference |
| role_id | bigint | FK → roles, not null, indexed | Role reference |
| assigned_by | bigint | FK → users | Who assigned this role |
| assigned_at | datetime | not null | When role was assigned |
| created_at | datetime | not null | Record creation timestamp |
| updated_at | datetime | not null | Record update timestamp |

**Indexes**:
- `user_id, role_id` (composite unique)
- `role_id`

**What this table tracks:**
- **Owner**: The user who created the venue
- **Admins**: Senior staff with most permissions
- **Receptionists**: Front desk staff managing bookings
- **Staff**: General staff assisting customers
- **Customers**: Regular users who book courts

**Notes**:
- **Simplified from original** `user_venue_roles`: Removed `venue_id` since MVP is single venue
- A user can have multiple roles (e.g., someone can be both receptionist and admin)
- `assigned_by` tracks who granted the role (audit trail)
- **Future**: When multi-venue is added, this becomes `user_venue_roles` with venue_id column
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

**How to display human-readable history to owner:**

Database data:
```json
[
  {
    "action": "created",
    "user_name": "Ahmed Khan",
    "created_at": "2026-04-07 10:30:00"
  },
  {
    "action": "updated",
    "user_name": "Receptionist Sara",
    "changes": {

    },
    "created_at": "2026-04-07 11:00:00"
  },
  {
    "action": "cancelled",
    "user_name": "Ahmed Khan",
    "changes": {"cancellation_reason": "Personal emergency"},
    "created_at": "2026-04-07 12:00:00"
  }
]
```

Display in UI:
```
• Apr 7, 10:30 AM - Ahmed Khan created this booking
• **MVP**: One-time closures only (specific date/time blocks)
- **Future**: R
    - Start time: 2:00 PM → 3:00 PM  
    - Court: Court 1 → Court 2
• Apr 7, 12:00 PM - Ahmed Khan cancelled (Reason: Personal emergency)
```

Build readable messages using the `action` field and parsing the `changes` JSON.

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
| **MVP**: In-app notifications only (displayed in web/mobile interface)
- **Future**: Email and SMS notifications for important alertenormalized for queries) |
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
-  Future Tables (Not in MVP)Venue-wide announcements
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

**Not. Multiple Venues Support
**Why deferred**: MVP focuses on single venue per owner. Multi-venue adds significant complexity.

**Changes needed when implementing:**
- Add back `venue_id` to `user_roles` table (becomes `user_venue_roles`)
- Support multiple venue records per owner
- Cross-venue role assignments
- Venue switching in UI

---

### 2. venue_reviews
User ratings and reviews for venues.

**Why deferred**: Reviews are valuable but not essential for core booking functionality.

**Schema when implemented:**
```
- venue_id → Venue being reviewed
- user_id → Reviewer
- booking_id → Related booking (proof of visit)
- rating (1-5)
- comment
- owner response
- is_published (moderation)
```

---

### 3. Recurring Court Closures
**Why deferred**: MVP only needs one-time closure blocks. Recurring patterns add complexity.

**Schema changes when implemented:**
- Add `is_recurring` boolean to `court_closures`
- Add `recurrence_rule` (iCalendar RRULE format)
- Example: "Every Monday 6-8 AM for cleaning"

---

### 4. Email/SMS Notifications
**Why deferred**: In-app notifications sufficient for MVP. Email/SMS requires integration with services.

**Implementation notes:**
- Add notification channels (email, SMS, push)
- Integrate with SendGrid/Twilio
- User preferences for notification types

---

### 5. memberships
For recurring memberships and reserved slots.

**Schema:**
- user_id, venue_id
- membership_plan_id
- starts_at, ends_at
- status (active, expired, cancelled)

---

### 6. equipment_rentals
Track equipment rented during bookings (rackets, balls, etc.).

**Schema:**
- booking_id
- equipment_id
- quantity, rental_fee

---
roles(user_id, role_id)` - Simplified for single venue
- `bookings.booking_number`
- `venue_settings.venue_id`
- `venue_operating_hours(venue_id, day_of_week)`
- code, description
- discount_type (percentage, fixed_amount)
- discount_value
- max_uses, used_count
- valid_from, valid_until

---

### 8. Online Payments
**Why deferred**: MVP uses cash payments only. Online payments require payment gateway integration.

**Future integration:**
- Stripe/Razorpay/JazzCash integration
- Partial payments, deposits, refunds
- Payment receipts and invoices fixed_amount |
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

### Uniqueroles → users, roles`
  - `booking_logs → bookings`
  - `court_closures → courts, venues`
  - `notifications → users` (SET NULL for venue, booking if deleted)e per venue
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
- `bookingRoles**: 
   - `(user_id, role_id)` - Simplified for single venue
   - `role_id` - All users with specific role set)
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
  - `user_venue_roles → users, venues, ro

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
- Tennisrole_id)`: Fast permission checks per user
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
- update:bookings (o
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
user.venues # Through use (MVP - Single Venue)
```
1. If user.is_global_admin? → Grant access
2. Get user's roles (user_roles)
3. Get permissions for those roles (role_permissions)
4. Check if required permission exists
5. Grant/Deny access
```

Example code:
```ruby
# Get user's roles
user.roles # Through user_roles

# Check permission
user.can?(:create, :bookings)
user.can?(:read, :reports
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

## Schema ility Points

The schema is designed to be extensible:

1. **Add new resources**: Simply create new permissions with resource name
2. **Custom roles**: `is_custom` flag allows venue-specific roles
3. **Dynamic pricing**: Multiple pricing rules with priority system
4. **Time slots**: No hardcoded slots, dynamically generated

7. **Future Enhancements**
   - venue_reviews (moved to future)
   - multi-venue support (user_venue_roles): Separate data per venue, efficient querying with indexes
8. **Audit trail**: booking_logs tracks all changes
9. **Geographic search**: latitude/longitude ready for location-based queries
10. **Court maintenance**: Flexible court_closures with recurring patterns support
11. **Notifications**: Extensible notification types for various alerts and reminders
12. **Reviews**: Support for venue/court ratings, responses, and moderation
13. **Emergency contacts**: User safety and liability protection
14. **Future payments**: Schema ready for deposits, partial payments, refunds

---

## Final Confirmation Checklist
custom roles
3. **Dynamic pricing**: Multiple pricing rules with priority system
4. **Time slots**: No hardcoded slots, dynamically generated
5. **Payment methods**: `payment_method` and `payment_status` ready for future gateway integration
6. **Cancellation policies**: `cancellation_hours` in venue_settings, tracking in bookings
7. **Audit trail**: booking_logs tracks all changes with human-readable history
8. **Geographic search**: latitude/longitude ready for Google Maps integration and distance calculations
9. **Court maintenance**: court_closures for blocking time periods
10. **Notifications**: Extensible notification types (in-app for MVP)
11. **Emergency contacts**: User safety and liability protection
12. **Future expansion**: Easy to add multi-venue support (add venue_id to user_roles), reviews, recurring closures, email/SMS notification
- **Booking number format**: Is `BK-{venue_code}-{YYYYMMDD}-{sequential}` acceptable?
- **Average rating cache**: Should we cache average rating on venues table for performance?
- **Review moderation**: Should reviews require approval before being published?
- **Notification channels**: In-app only, or also email/SMS/push?
---

## Summary of MVP Simplifications

| Original Feature | MVP Change | Reason |
|-----------------|------------|--------|
| Multi-venue support | Single venue only | Reduces complexity, focus on core booking |
| user_venue_roles | user_roles (no venue_id) | Simpler for single venue |
| is_system_role + is_custom | Only is_custom boolean | One boolean sufficient |
| venue_reviews | Moved to future | Not critical for booking operations |
| Recurring closures | One-time only | Simpler for MVP |
| Email/SMS notifications | In-app only | Avoid third-party integration initially |
| average_rating in venues | Removed | No reviews in MVP |

**Key MVP Features Retained:**
- Dynamic time slot generation
- Flexible pricing rules (time-based, court-type-based)
- Role-based permissions with custom roles
- Booking audit trail (booking_logs)
- Court closures for maintenance
- In-app notifications
- Pakistan timezone (Asia/Karachi) and PKR currency defaults
- Google Maps integration (lat/long)

---

*Last Updated: 2026-04-07*
*Status: **MVP Schema - Ready for Implementation**

**MVP Scope (Included):**
1. ✅ **Single venue per owner**: Simplified from multi-venue
2. ✅ **User roles**: Simplified `user_roles` (no venue_id)
3. ✅ **Court maintenance**: court_closures (one-time only for MVP)
4. ✅ **Notifications**: In-app only for MVP
5. ✅ **Emergency contacts**: Added to users table
6. ✅ **Dynamic time slots**: Generated on-the-fly with configurable durations
7. ✅ **Flexible pricing**: Time-based pricing rules with examples in PKR
8. ✅ **Audit trail**: booking_logs with human-readable history guide
9. ✅ **Google Maps**: Latitude/longitude for map link generation
10. ✅ **Payments**: Cash only for MVP

**Deferred to Future (Not in MVP):**
1. ⏸️ **Multiple venues**: Owner can have many venues
2. ⏸️ **Reviews**: venue_reviews table
3. ⏸️ **Recurring closures**: iCalendar RRULE support
4. ⏸️ **Email/SMS notifications**: Only in-app for now
5. ⏸️ **Memberships**: Reserved slots, recurring bookings
6. ⏸️ **Equipment rentals**: Track rented items
7. ⏸️ **Discounts/coupons**: Promotional codes
8. ⏸️ **Online payments**: Stripe/Razorpay integration

---

## Database Relationships Overview

Visual representation of how all tables connect to each other.

### One-to-One Relationships

| Parent Table | Child Table | Relationship | Description |
|--------------|-------------|--------------|-------------|
| venues | venue_settings | 1:1 | Each venue has exactly one settings record |

**Notes:**
- Enforced by unique constraint on `venue_settings.venue_id`
- Settings are required for each venue

---

### One-to-Many Relationships

| Parent (One) | Child (Many) | Foreign Key | Description |
|--------------|--------------|-------------|-------------|
| **users** | venues | venues.owner_id | One user owns one/many venues (MVP: one only) |
| **venues** | venue_operating_hours | venue_operating_hours.venue_id | One venue has 7 operating hour records (Mon-Sun) |
| **venues** | courts | courts.venue_id | One venue has many courts |
| **venues** | pricing_rules | pricing_rules.venue_id | One venue has many pricing rules |
| **venues** | court_closures | court_closures.venue_id | One venue has many court closures |
| **venues** | bookings | bookings.venue_id | One venue has many bookings (denormalized) |
| **court_types** | courts | courts.court_type_id | One sport type (Tennis) has many courts |
| **courts** | bookings | bookings.court_id | One court has many bookings |
| **courts** | court_closures | court_closures.court_id | One court has many closure periods |
| **users** | bookings | bookings.user_id | One user (customer) makes many bookings |
| **users** | bookings | bookings.created_by | One user (staff) creates many bookings |
| **users** | bookings | bookings.cancelled_by | One user cancels many bookings |
| **users** | bookings | bookings.checked_in_by | One user (receptionist) checks in many bookings |
| **users** | user_roles | user_roles.user_id | One user has many roles |
| **users** | user_roles | user_roles.assigned_by | One user assigns many roles to others |
| **users** | booking_logs | booking_logs.user_id | One user creates many booking log entries |
| **users** | court_closures | court_closures.created_by | One user creates many court closures |
| **users** | notifications | notifications.user_id | One user receives many notifications |
| **bookings** | booking_logs | booking_logs.booking_id | One booking has many log entries (audit trail) |
| **bookings** | notifications | notifications.booking_id | One booking triggers many notifications |
| **venues** | notifications | notifications.venue_id | One venue has many notifications |
| **roles** | user_roles | user_roles.role_id | One role assigned to many users |
| **roles** | role_permissions | role_permissions.role_id | One role has many permissions |
| **permissions** | role_permissions | role_permissions.permission_id | One permission belongs to many roles |

**Key Patterns:**
- **Denormalization**: `bookings.venue_id` is denormalized from court for faster queries
- **Multiple FKs to same table**: Users table has multiple relationships to bookings (user, creator, canceller, checker)
- **Audit trails**: booking_logs, user_roles.assigned_by track who did what

---

### Many-to-Many Relationships

| Table A | Table B | Join Table | Description |
|---------|---------|------------|-------------|
| **users** | **roles** | user_roles | Users can have multiple roles; roles can be assigned to multiple users |
| **roles** | **permissions** | role_permissions | Roles have multiple permissions; permissions belong to multiple roles |

**Join Table Details:**

**user_roles** (users ↔ roles):
```
- user_id → users
- role_id → roles
- assigned_by → users (audit)
- assigned_at
```
- **Example**: User "Ahmed" has roles: [customer, receptionist]
- **Example**: Role "receptionist" assigned to users: [Sara, Ali, Fatima]

**role_permissions** (roles ↔ permissions):
```
- role_id → roles
- permission_id → permissions
```
- **Example**: Role "receptionist" has permissions: [create:bookings, read:bookings, update:bookings, read:courts]
- **Example**: Permission "read:bookings" belongs to roles: [owner, admin, receptionist, staff]

---

### Complete Entity Relationship Diagram (Text Format)

```
users (Primary Entity)
├─ owns → venues (1:many, MVP: 1:1)
├─ has → user_roles (1:many)
│  └─ connects to → roles (many:many via user_roles)
├─ makes → bookings (1:many via user_id)
├─ creates → bookings (1:many via created_by)
├─ cancels → bookings (1:many via cancelled_by)
├─ checks in → bookings (1:many via checked_in_by)
├─ assigns → user_roles (1:many via assigned_by)
├─ creates → court_closures (1:many)
├─ logs → booking_logs (1:many)
└─ receives → notifications (1:many)

venues
├─ has → venue_settings (1:1) ⭐
├─ has → venue_operating_hours (1:many - 7 days)
├─ has → courts (1:many)
├─ has → pricing_rules (1:many)
├─ has → court_closures (1:many)
├─ has → bookings (1:many - denormalized)
└─ has → notifications (1:many)

venue_settings
└─ belongs to → venues (1:1) ⭐

venue_operating_hours
└─ belongs to → venues (many:1)

court_types
└─ has → courts (1:many)

courts
├─ belongs to → venues (many:1)
├─ is of type → court_types (many:1)
├─ has → bookings (1:many)
└─ has → court_closures (1:many)

pricing_rules
├─ belongs to → venues (many:1)
└─ applies to → court_types (many:1)

bookings
├─ belongs to → users (many:1 via user_id)
├─ created by → users (many:1 via created_by)
├─ cancelled by → users (many:1 via cancelled_by)
├─ checked in by → users (many:1 via checked_in_by)
├─ belongs to → courts (many:1)
├─ belongs to → venues (many:1 - denormalized)
├─ has → booking_logs (1:many)
└─ triggers → notifications (1:many)

booking_logs
├─ belongs to → bookings (many:1)
└─ created by → users (many:1)

court_closures
├─ belongs to → courts (many:1)
├─ belongs to → venues (many:1 - denormalized)
└─ created by → users (many:1)

roles
├─ has → user_roles (1:many)
│  └─ connects to → users (many:many via user_roles)
└─ has → role_permissions (1:many)
   └─ connects to → permissions (many:many via role_permissions)

permissions
└─ has → role_permissions (1:many)
   └─ connects to → roles (many:many via role_permissions)

user_roles (Join Table)
├─ belongs to → users (many:1)
├─ belongs to → roles (many:1)
└─ assigned by → users (many:1 via assigned_by)

role_permissions (Join Table)
├─ belongs to → roles (many:1)
└─ belongs to → permissions (many:1)

notifications
├─ belongs to → users (many:1)
├─ related to → venues (many:1, optional)
└─ related to → bookings (many:1, optional)
```

**Legend:**
- `→` indicates direction of relationship
- `⭐` indicates one-to-one relationship
- `1:1` = one-to-one
- `1:many` = one-to-many
- `many:1` = many-to-one (reverse of 1:many)
- `many:many` = many-to-many (through join table)

---

### Relationship Summary

| Relationship Type | Count | Tables |
|------------------|-------|--------|
| **One-to-One** | 1 | venues ↔ venue_settings |
| **One-to-Many** | 24 | See detailed list above |
| **Many-to-Many** | 2 | users ↔ roles, roles ↔ permissions |
| **Total Tables** | 16 | MVP Schema |

**Central Tables (High Connectivity):**
1. **users** - 10 relationships (owns venue, makes bookings, creates logs, etc.)
2. **venues** - 7 relationships (settings, hours, courts, pricing, closures, bookings, notifications)
3. **bookings** - 6 relationships (user, court, venue, logs, notifications, multiple user FKs)
4. **courts** - 4 relationships (venue, court_type, bookings, closures)
5. **roles** - 2 relationships (users, permissions)

**Isolated Tables (Low Connectivity):**
1. **court_types** - 1 relationship (courts)
2. **permissions** - 1 relationship (roles)
3. **venue_settings** - 1 relationship (venues)

---

## Next Steps

1. **Review & Confirm**: ✅ MVP schema finalized
2. **Implementation Order**:
   - Create Rails migrations in sequence (see "Schema Migration Order" section)
   - Setup models with associations
   - Implement validation rules
   - Create seed data (court types, system roles, permissions)
   - Setup permission system (CanCanCan or Pundit)
   - Build time slot generation service
   - Implement booking service with double-booking prevention
3. **Start with**: Core user authentication and single venue setup
