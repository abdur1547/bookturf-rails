# BookTruf API v0 — Comprehensive Endpoint Reference

**Version:** 1.0 — Comprehensive Reference for All Platforms
**Last Updated:** April 2026
**Scope:** iOS app · Android app · Owner web dashboard · Staff web view · Public web pages

---

## Table of Contents

1. [Overview & Authentication](#1-overview--authentication)
2. [Response Format](#2-response-format)
3. [Authentication Endpoints](#3-authentication-endpoints)
4. [User Management Endpoints](#4-user-management-endpoints)
5. [Cities & Sports Discovery](#5-cities--sports-discovery)
6. [Venues Management](#6-venues-management)
7. [Courts Management](#7-courts-management)
8. [Pricing Rules](#8-pricing-rules)
9. [Bookings](#9-bookings)
10. [Reviews & Ratings](#10-reviews--ratings)
11. [Staff Management](#11-staff-management)
12. [Court Closures & Maintenance](#12-court-closures--maintenance)
13. [Media & Images](#13-media--images)
14. [Reports & Analytics](#14-reports--analytics)
15. [Audit Logs](#15-audit-logs)
16. [Shareable Links & Public Pages](#16-shareable-links--public-pages)
17. [User Preferences & Settings](#17-user-preferences--settings)
18. [Error Responses](#18-error-responses)

---

## 1. Overview & Authentication

### Authentication Methods

All protected endpoints require authentication via one of:

- **Authorization Header:** `Authorization: Bearer <access_token>`
- **Cookies:** `access_token` and `refresh_token` cookies (for web clients)

### User Roles

- **Customer:** Books courts, leaves reviews, manages own bookings
- **Staff:** Creates manual bookings, confirms/cancels bookings, views all venue bookings
- **Owner:** Manages venues, courts, staff, pricing, reports, settings
- **Admin:** Platform-level access (if applicable)

---

## 2. Response Format

### Success Response

All successful responses follow this wrapper:

```json
{
  "success": true,
  "data": {
    "id": 123,
    "name": "Example",
    ...
  }
}
```

### List Response

Paginated list responses include metadata:

```json
{
  "success": true,
  "data": [
    { "id": 1, "name": "Item 1" },
    { "id": 2, "name": "Item 2" }
  ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 100,
    "total_pages": 5
  }
}
```

### Error Response

```json
{
  "success": false,
  "errors": [
    "Field validation error",
    "Authorization failed"
  ]
}
```

---

## 3. Authentication Endpoints

### POST /api/v0/auth/signup

Creates a new user account and returns auth tokens.

**Request Body:**
```json
{
  "first_name": "string",
  "last_name": "string",
  "email": "string",
  "password": "string",
  "password_confirmation": "string"
}
```

**Response Data:**
```json
{
  "id": "integer",
  "email": "string",
  "first_name": "string",
  "last_name": "string",
  "name": "string",
  "avatar_url": "string|null",
  "user_type": "customer|owner|staff",
  "created_at": "ISO8601 string",
  "access_token": "Bearer <token>",
  "refresh_token": "string"
}
```

**Status Codes:** 201 Created, 422 Unprocessable Entity

---

### POST /api/v0/auth/signin

Signs in an existing user and returns auth tokens.

**Request Body:**
```json
{
  "email": "string",
  "password": "string"
}
```

**Response Data:**
```json
{
  "id": "integer",
  "email": "string",
  "name": "string",
  "user_type": "customer|owner|staff",
  "avatar_url": "string|null",
  "access_token": "Bearer <token>",
  "refresh_token": "string"
}
```

**Status Codes:** 200 OK, 401 Unauthorized

---

### POST /api/v0/auth/google

OAuth sign-up/sign-in via Google.

**Request Body:**
```json
{
  "id_token": "string",
  "access_token": "string",
  "user_type": "customer|owner"
}
```

**Response Data:**
```json
{
  "id": "integer",
  "email": "string",
  "name": "string",
  "user_type": "customer|owner",
  "avatar_url": "string|null",
  "is_oauth_signup": "boolean",
  "access_token": "Bearer <token>",
  "refresh_token": "string"
}
```

**Status Codes:** 200 OK, 201 Created

---

### POST /api/v0/auth/apple

OAuth sign-up/sign-in via Apple.

**Request Body:**
```json
{
  "identity_token": "string",
  "user_id": "string",
  "user_type": "customer|owner",
  "email": "string|null",
  "first_name": "string|null",
  "last_name": "string|null"
}
```

**Response Data:** Same as Google OAuth

**Status Codes:** 200 OK, 201 Created

---

### POST /api/v0/auth/refresh

Refreshes tokens using the refresh token.

**Request Body:**
```json
{
  "refresh_token": "string"
}
```

**Response Data:**
```json
{
  "access_token": "Bearer <token>",
  "refresh_token": "string"
}
```

**Status Codes:** 200 OK, 401 Unauthorized

---

### DELETE /api/v0/auth/signout

Invalidates current session tokens.

**Requires:** Authentication

**Response Data:**
```json
{
  "message": "Successfully signed out"
}
```

**Status Codes:** 200 OK, 401 Unauthorized

---

### POST /api/v0/auth/reset_password

Requests a password reset OTP for an email.

**Request Body:**
```json
{
  "email": "string"
}
```

**Response Data:**
```json
{
  "message": "If an account exists with this email, you will receive a password reset code shortly."
}
```

**Status Codes:** 200 OK

---

### POST /api/v0/auth/verify_reset_otp

Verifies reset OTP and sets a new password.

**Request Body:**
```json
{
  "email": "string",
  "otp_code": "string",
  "password": "string",
  "password_confirmation": "string"
}
```

**Response Data:**
```json
{
  "message": "Your password has been successfully reset. You can now sign in with your new password."
}
```

**Status Codes:** 200 OK, 422 Unprocessable Entity

---

### POST /api/v0/auth/send_verification_email

Sends verification email (for email signup flow).

**Request Body:**
```json
{
  "email": "string"
}
```

**Response Data:**
```json
{
  "message": "Verification email sent to your email address"
}
```

**Status Codes:** 200 OK, 422 Unprocessable Entity

---

### POST /api/v0/auth/verify_email

Verifies email using verification token.

**Request Body:**
```json
{
  "email": "string",
  "verification_token": "string"
}
```

**Response Data:**
```json
{
  "message": "Email verified successfully",
  "user": {
    "id": "integer",
    "email": "string",
    "name": "string",
    "email_verified_at": "ISO8601 string"
  }
}
```

**Status Codes:** 200 OK, 422 Unprocessable Entity

---

## 4. User Management Endpoints

### GET /api/v0/me

Get current authenticated user profile.

**Requires:** Authentication

**Response Data:**
```json
{
  "id": "integer",
  "email": "string",
  "first_name": "string",
  "last_name": "string",
  "name": "string",
  "phone": "string|null",
  "avatar_url": "string|null",
  "user_type": "customer|owner|staff",
  "email_verified_at": "ISO8601 string|null",
  "created_at": "ISO8601 string",
  "updated_at": "ISO8601 string",
  "preferences": {
    "preferred_city": "string|null",
    "preferred_town": "string|null",
    "notification_reminders": "boolean",
    "notification_30min": "boolean"
  },
  "owner_data": {
    "venue_id": "integer|null",
    "onboarding_step": "0-4",
    "onboarding_completed": "boolean"
  } | null,
  "staff_data": {
    "venue_id": "integer|null",
    "joined_at": "ISO8601 string"
  } | null
}
```

**Status Codes:** 200 OK, 401 Unauthorized

---

### PATCH /api/v0/users/:id

Update user profile.

**Requires:** Authentication (user can only update own profile)

**Request Body:**
```json
{
  "first_name": "string|null",
  "last_name": "string|null",
  "phone": "string|null",
  "avatar_url": "string|null"
}
```

**Response Data:** Same as GET /api/v0/me

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden, 422 Unprocessable Entity

---

### POST /api/v0/users/avatar

Upload user avatar (multipart form).

**Requires:** Authentication

**Form Data:**
- `avatar` (file): Image file (max 5MB, supported: jpg, jpeg, png, webp)

**Response Data:**
```json
{
  "avatar_url": "string",
  "message": "Avatar uploaded successfully"
}
```

**Status Codes:** 200 OK, 400 Bad Request, 413 Payload Too Large

---

### PATCH /api/v0/users/:id/password

Change password.

**Requires:** Authentication (user can only change own password)

**Request Body:**
```json
{
  "current_password": "string",
  "password": "string",
  "password_confirmation": "string"
}
```

**Response Data:**
```json
{
  "message": "Password changed successfully"
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 422 Unprocessable Entity

---

### DELETE /api/v0/users/:id

Delete user account and all associated data.

**Requires:** Authentication (user can only delete own account)

**Request Body:**
```json
{
  "password": "string"
}
```

**Response Data:**
```json
{
  "message": "Account deleted successfully"
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

## 5. Cities & Sports Discovery

### GET /api/v0/cities

List all available cities with sports count.

**Query Params:**
- `page` (optional): integer, default: 1
- `per_page` (optional): integer, default: 20
- `search` (optional): string, search cities by name
- `country` (optional): string, filter by country

**Response Data:**
```json
[
  {
    "id": "integer",
    "name": "string",
    "slug": "string",
    "country": "string|null",
    "state": "string|null",
    "latitude": "number|null",
    "longitude": "number|null",
    "sports_count": "integer",
    "courts_count": "integer",
    "venues_count": "integer",
    "areas": [
      {
        "id": "integer",
        "name": "string",
        "slug": "string"
      }
    ]
  }
]
```

**Status Codes:** 200 OK

---

### GET /api/v0/cities/:id

Get city details with sports and areas.

**Response Data:**
```json
{
  "id": "integer",
  "name": "string",
  "slug": "string",
  "country": "string|null",
  "state": "string|null",
  "latitude": "number|null",
  "longitude": "number|null",
  "sports_count": "integer",
  "courts_count": "integer",
  "venues_count": "integer",
  "areas": [
    {
      "id": "integer",
      "name": "string",
      "slug": "string",
      "courts_count": "integer"
    }
  ],
  "created_at": "ISO8601 string"
}
```

**Status Codes:** 200 OK, 404 Not Found

---

### GET /api/v0/sports

List all sports types available on platform.

**Query Params:**
- `page` (optional): integer, default: 1
- `per_page` (optional): integer, default: 50
- `city_id` (optional): integer, filter by city
- `active_only` (optional): boolean, only sports with available courts

**Response Data:**
```json
[
  {
    "id": "integer",
    "name": "string",
    "slug": "string",
    "description": "string|null",
    "icon_url": "string|null",
    "is_active": "boolean",
    "courts_count": "integer",
    "created_at": "ISO8601 string"
  }
]
```

**Status Codes:** 200 OK

---

### GET /api/v0/sports/:id

Get sport type details.

**Response Data:**
```json
{
  "id": "integer",
  "name": "string",
  "slug": "string",
  "description": "string|null",
  "icon_url": "string|null",
  "is_active": "boolean",
  "courts_count": "integer",
  "created_at": "ISO8601 string",
  "updated_at": "ISO8601 string"
}
```

**Status Codes:** 200 OK, 404 Not Found

---

### GET /api/v0/sports/:id/courts

List courts for a specific sport in a city.

**Query Params:**
- `city_id` (required): integer
- `area_id` (optional): integer, filter by area/town
- `page` (optional): integer, default: 1
- `per_page` (optional): integer, default: 20
- `sort` (optional): `distance`, `rating`, `price` (default: distance)
- `search` (optional): string, search courts by name or venue

**Response Data:**
```json
[
  {
    "id": "integer",
    "name": "string",
    "venue_id": "integer",
    "venue_name": "string",
    "sport_type": "string",
    "price_range": {
      "min": "number",
      "max": "number",
      "currency": "string"
    },
    "rating": "number|null",
    "review_count": "integer",
    "distance_km": "number|null",
    "area": "string",
    "images": ["string"],
    "available_slots_today": "integer"
  }
]
```

**Status Codes:** 200 OK, 404 Not Found

---

## 6. Venues Management

### GET /api/v0/venues

List venues (public view and owner filtered).

**Query Params:**
- `page` (optional): integer, default: 1
- `per_page` (optional): integer, default: 10, max: 100
- `city` (optional): string
- `state` (optional): string
- `country` (optional): string
- `search` (optional): string, search by name, address, city, or description
- `sort` (optional): `name`, `city`, `created_at`
- `order` (optional): `asc`, `desc`
- `is_active` (optional): boolean, default: true (only active venues returned when omitted)

**Response Data:**
```json
[
  {
    "id": "integer",
    "name": "string",
    "slug": "string",
    "description": "string|null",
    "address": "string",
    "city": "string",
    "state": "string",
    "country": "string",
    "postal_code": "string|null",
    "phone_number": "string|null",
    "email": "string|null",
    "is_active": "boolean",
    "latitude": "number|null",
    "longitude": "number|null",
    "google_maps_url": "string|null",
    "timezone": "string",
    "currency": "string",
    "courts_count": "integer",
    "created_at": "ISO8601 string"
  }
]
```

**Status Codes:** 200 OK

---

### GET /api/v0/venues/:id

Get venue details including operating hours.

**Path Params:**
- `id` (required): venue ID or slug

**Response Data:**
```json
{
  "id": "integer",
  "name": "string",
  "slug": "string",
  "description": "string|null",
  "address": "string",
  "city": "string",
  "state": "string",
  "country": "string",
  "postal_code": "string|null",
  "phone_number": "string|null",
  "email": "string|null",
  "is_active": "boolean",
  "latitude": "number|null",
  "longitude": "number|null",
  "google_maps_url": "string|null",
  "timezone": "string",
  "currency": "string",
  "courts_count": "integer",
  "created_at": "ISO8601 string",
  "updated_at": "ISO8601 string",
  "owner": {
    "id": "integer",
    "full_name": "string"
  },
  "venue_operating_hours": [
    {
      "id": "integer",
      "day_of_week": "0-6",
      "day_name": "string",
      "is_closed": "boolean",
      "opens_at": "string",
      "closes_at": "string",
      "formatted_hours": "string"
    }
  ]
}
```

**Status Codes:** 200 OK, 404 Not Found

---

### POST /api/v0/venues

Create a new venue (owner onboarding - Step 1).

**Requires:** Authentication (owner only)

**Request Body:**
```json
{
  "name": "string",
  "description": "string|null",
  "address": "string",
  "city": "string",
  "state": "string",
  "country": "string",
  "postal_code": "string|null",
  "latitude": "number|null",
  "longitude": "number|null",
  "phone_number": "string|null",
  "email": "string|null",
  "is_active": "boolean|null",
  "timezone": "string|null",               // default to "Asia/Karachi" — IANA timezone identifier
  "currency": "string|null",               // default to "PKR" — ISO 4217 currency code
  "venue_operating_hours": [ // optional
    {
      "day_of_week": "integer (0-6)",  // 0=Monday, 6=Sunday
      "opens_at": "string|null",       // Time format: HH:MM (e.g., "09:00"). Required if is_closed is false
      "closes_at": "string|null",      // Time format: HH:MM (e.g., "23:00"). Required if is_closed is false. Must be after opens_at
      "is_closed": "boolean|null"      // If true, opens_at and closes_at are ignored
    }
  ]
}
```

**Notes:**
- `venue_operating_hours` is optional. If not provided, defaults to: open all days, Monday (0) to Sunday (6), from 09:00 to 23:00.
- If provided, must contain exactly 7 entries (one for each day of the week from 0-6).
- Each `day_of_week` must be unique and in the range 0-6.
- Time format must be HH:MM in 24-hour format (e.g., "09:00", "23:30").
- If `is_closed` is false, both `opens_at` and `closes_at` are required.
- `closes_at` must be after `opens_at` (e.g., "09:00" closes_at "23:00" is valid, but "23:00" closes_at "09:00" is invalid).

**Response Data:** Same as GET /api/v0/venues/:id

**Status Codes:** 201 Created, 401 Unauthorized, 422 Unprocessable Entity

---

### PATCH /api/v0/venues/:id

Update venue details.

**Requires:** Authentication (owner only)

**Request Body:** Same as POST (all fields optional)

**Response Data:** Same as GET /api/v0/venues/:id

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden, 422 Unprocessable Entity

---

### ~~PATCH /api/v0/venues/:id/operating_hours~~

Update venue operating hours (onboarding - Step 2).

**Requires:** Authentication (owner only)

**Request Body:**
```json
{
  "operating_hours": [
    {
      "day_of_week": "0-6",
      "is_closed": "boolean",
      "opens_at": "HH:MM|null",
      "closes_at": "HH:MM|null"
    }
  ]
}
```

**Response Data:** Same as GET /api/v0/venues/:id

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden, 422 Unprocessable Entity

---

### PATCH /api/v0/venues/:id/onboarding_step

Update owner onboarding step.

**Requires:** Authentication (owner only)

**Request Body:**
```json
{
  "onboarding_step": "integer (0-4)"
}
```

**Response Data:** Same as GET /api/v0/venues/:id, with two additional fields appended:
```json
{
  "...": "all fields from GET /api/v0/venues/:id",
  "onboarding_step": "integer",
  "onboarding_completed": "boolean"
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 422 Unprocessable Entity

---

### DELETE /api/v0/venues/:id

Delete a venue.

**Requires:** Authentication (owner only)

**Response Data:**
```json
{
  "message": "Venue deleted successfully"
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### GET /api/v0/venues/:id/availability

Check venue availability for date range.

**Query Params:**
- `start_date` (required): date string (YYYY-MM-DD)
- `end_date` (optional): date string (YYYY-MM-DD), defaults to start_date
- `duration_minutes` (optional): integer, defaults to minimum slot duration
- `court_type_id` (optional): integer
- `court_id` (optional): integer
- `include_booked` (optional): boolean

**Response Data:**
```json
{
  "venue_id": "integer",
  "start_date": "YYYY-MM-DD",
  "end_date": "YYYY-MM-DD",
  "timezone": "string",
  "court_availability": [
    {
      "court_id": "integer",
      "court_name": "string",
      "slots": [
        {
          "start_time": "ISO8601 string",
          "end_time": "ISO8601 string",
          "duration_minutes": "integer",
          "price_per_hour": "string",
          "total_amount": "string",
          "available": "boolean",
          "booked": "boolean",
          "booking_status": "confirmed|closed|null"
        }
      ]
    }
  ]
}
```

**Status Codes:** 200 OK, 404 Not Found

---

## 7. Courts Management

### GET /api/v0/courts

List courts with filtering.

**Query Params:**
- `page` (optional): integer, default: 1
- `per_page` (optional): integer, default: 20
- `venue_id` (optional): integer
- `sport_type_id` (optional): integer
- `city_id` (optional): integer
- `area_id` (optional): integer
- `is_active` (optional): boolean
- `search` (optional): string
- `sort` (optional): `name`, `created_at`, `display_order`
- `order` (optional): `asc`, `desc`

**Response Data:**
```json
[
  {
    "id": "integer",
    "name": "string",
    "description": "string|null",
    "sport_type_id": "integer",
    "sport_type_name": "string",
    "venue_id": "integer",
    "venue_name": "string",
    "city": "string",
    "minimum_slot_duration": "integer",
    "maximum_slot_duration": "integer",
    "slot_interval": "integer",
    "requires_approval": "boolean",
    "is_active": "boolean",
    "display_order": "integer|null",
    "price_range": {
      "min": "number",
      "max": "number"
    },
    "images": [
      {
        "id": "integer",
        "url": "string"
      }
    ],
    "created_at": "ISO8601 string"
  }
]
```

**Status Codes:** 200 OK

---

### GET /api/v0/courts/:id

Get court details.

**Response Data:**
```json
{
  "id": "integer",
  "name": "string",
  "description": "string|null",
  "sport_type_id": "integer",
  "sport_type_name": "string",
  "venue_id": "integer",
  "venue_name": "string",
  "minimum_slot_duration": "integer",
  "maximum_slot_duration": "integer",
  "slot_interval": "integer",
  "requires_approval": "boolean",
  "is_active": "boolean",
  "display_order": "integer|null",
  "price_range": {
    "min": "number",
    "max": "number"
  },
  "images": [
    {
      "id": "integer",
      "url": "string",
      "alt_text": "string|null",
      "display_order": "integer"
    }
  ],
  "pricing_rules": [
    {
      "id": "integer",
      "name": "string",
      "day_of_week": "0-6|null",
      "day_name": "string|null",
      "start_time": "HH:MM|null",
      "end_time": "HH:MM|null",
      "price_per_hour": "number",
      "priority": "integer"
    }
  ],
  "created_at": "ISO8601 string",
  "updated_at": "ISO8601 string"
}
```

**Status Codes:** 200 OK, 404 Not Found

---

### POST /api/v0/courts

Create a new court (onboarding - Step 3).

**Requires:** Authentication (owner only)

**Request Body:**
```json
{
  "venue_id": "integer",
  "name": "string",
  "description": "string|null",
  "sport_type_id": "integer",
  "sport_type_name": "string",
  "minimum_slot_duration": "integer|null",  // default: 60 (minutes)
  "maximum_slot_duration": "integer|null",  // default: 180 (minutes)
  "slot_interval": "integer|null",          // default: 30 (minutes)
  "requires_approval": "boolean|null",      // default: false
  "is_active": "boolean|null",
  "display_order": "integer|null"
}
```

**Response Data:** Same as GET /api/v0/courts/:id

**Status Codes:** 201 Created, 401 Unauthorized, 422 Unprocessable Entity

---

### PATCH /api/v0/courts/:id

Update court details.

**Requires:** Authentication (owner only)

**Request Body:** Same as POST (all fields optional)

**Response Data:** Same as GET /api/v0/courts/:id

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden, 422 Unprocessable Entity

---

### DELETE /api/v0/courts/:id

Delete a court.

**Requires:** Authentication (owner only)

**Response Data:**
```json
{
  "message": "Court deleted successfully"
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### PATCH /api/v0/courts/:id/reorder

Reorder courts display order.

**Requires:** Authentication (owner only)

**Request Body:**
```json
{
  "display_order": "integer"
}
```

**Response Data:**
```json
{
  "id": "integer",
  "display_order": "integer"
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

## 8. Pricing Rules

### GET /api/v0/pricing_rules

List pricing rules for courts.

**Query Params:**
- `page` (optional): integer, default: 1
- `per_page` (optional): integer, default: 50
- `venue_id` (optional): integer
- `court_type_id` (optional): integer
- `is_active` (optional): boolean
- `day_of_week` (optional): integer (0-6)

**Requires:** Authentication (owner/staff only)

**Response Data:**
```json
[
  {
    "id": "integer",
    "venue_id": "integer",
    "court_type_id": "integer",
    "name": "string",
    "price_per_hour": "number",
    "day_of_week": "0-6|null",
    "day_name": "string|null",
    "start_time": "HH:MM|null",
    "end_time": "HH:MM|null",
    "start_date": "YYYY-MM-DD|null",
    "end_date": "YYYY-MM-DD|null",
    "priority": "integer",
    "is_active": "boolean",
    "time_range": "string|null",
    "created_at": "ISO8601 string",
    "updated_at": "ISO8601 string"
  }
]
```

**Status Codes:** 200 OK, 401 Unauthorized

---

### GET /api/v0/pricing_rules/:id

Get pricing rule details.

**Requires:** Authentication

**Response Data:** Same as list item

**Status Codes:** 200 OK, 404 Not Found

---

### POST /api/v0/pricing_rules

Create a pricing rule.

**Requires:** Authentication (owner only)

**Request Body:**
```json
{
  "venue_id": "integer",
  "court_type_id": "integer",
  "name": "string",
  "price_per_hour": "number",
  "day_of_week": "0-6|null",
  "start_time": "HH:MM|null",
  "end_time": "HH:MM|null",
  "start_date": "YYYY-MM-DD|null",
  "end_date": "YYYY-MM-DD|null",
  "priority": "integer",
  "is_active": "boolean|null"
}
```

**Response Data:** Same as GET

**Status Codes:** 201 Created, 401 Unauthorized, 422 Unprocessable Entity

---

### PATCH /api/v0/pricing_rules/:id

Update a pricing rule.

**Requires:** Authentication (owner only)

**Request Body:** Same as POST (all fields optional)

**Response Data:** Same as GET

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden, 422 Unprocessable Entity

---

### DELETE /api/v0/pricing_rules/:id

Delete a pricing rule.

**Requires:** Authentication (owner only)

**Response Data:**
```json
{
  "message": "Pricing rule deleted successfully"
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### POST /api/v0/pricing_rules/bulk_create

Create multiple pricing rules at once (for onboarding).

**Requires:** Authentication (owner only)

**Request Body:**
```json
{
  "pricing_rules": [
    {
      "court_type_id": "integer",
      "name": "string",
      "price_per_hour": "number",
      "day_of_week": "0-6|null",
      "start_time": "HH:MM|null",
      "end_time": "HH:MM|null",
      "priority": "integer"
    }
  ]
}
```

**Response Data:**
```json
{
  "created_count": "integer",
  "pricing_rules": [...]
}
```

**Status Codes:** 201 Created, 422 Unprocessable Entity

---

## 9. Bookings

### GET /api/v0/bookings

List bookings (filtered by user role).

**Query Params:**
- `page` (optional): integer, default: 1
- `per_page` (optional): integer, default: 20
- `status` (optional): `pending`, `confirmed`, `cancelled`, `completed`, `no_show`
- `user_id` (optional): integer
- `court_id` (optional): integer
- `venue_id` (optional): integer
- `from_date` (optional): YYYY-MM-DD
- `to_date` (optional): YYYY-MM-DD
- `sort` (optional): `created_at`, `start_time`
- `order` (optional): `asc`, `desc`

**Requires:** Authentication

**Response Data:**
```json
[
  {
    "id": "integer",
    "booking_number": "string",
    "status": "pending|confirmed|cancelled|completed|no_show",
    "user_id": "integer",
    "user_name": "string",
    "user_email": "string",
    "court_id": "integer",
    "court_name": "string",
    "venue_id": "integer",
    "venue_name": "string",
    "start_time": "ISO8601 string",
    "end_time": "ISO8601 string",
    "duration_minutes": "integer",
    "total_amount": "number",
    "paid_amount": "number|null",
    "payment_method": "string|null",
    "payment_status": "pending|completed|failed|null",
    "notes": "string|null",
    "created_by_id": "integer|null",
    "created_by_name": "string|null",
    "created_at": "ISO8601 string",
    "updated_at": "ISO8601 string"
  }
]
```

**Status Codes:** 200 OK, 401 Unauthorized

---

### GET /api/v0/bookings/:id

Get booking details.

**Requires:** Authentication

**Response Data:**
```json
{
  "id": "integer",
  "booking_number": "string",
  "status": "pending|confirmed|cancelled|completed|no_show",
  "user_id": "integer",
  "user_name": "string",
  "user_email": "string",
  "user_phone": "string|null",
  "court_id": "integer",
  "court_name": "string",
  "sport_type": "string",
  "venue_id": "integer",
  "venue_name": "string",
  "venue_address": "string",
  "venue_phone": "string|null",
  "start_time": "ISO8601 string",
  "end_time": "ISO8601 string",
  "duration_minutes": "integer",
  "total_amount": "number",
  "paid_amount": "number|null",
  "payment_method": "string|null",
  "payment_status": "pending|completed|failed|null",
  "notes": "string|null",
  "cancellation_reason": "string|null",
  "cancelled_at": "ISO8601 string|null",
  "checked_in_at": "ISO8601 string|null",
  "completed_at": "ISO8601 string|null",
  "created_by_id": "integer|null",
  "created_by_name": "string|null",
  "created_at": "ISO8601 string",
  "updated_at": "ISO8601 string"
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 404 Not Found

---

### POST /api/v0/bookings

Create a new booking.

**Requires:** Authentication

**Request Body:**
```json
{
  "user_id": "integer|null",
  "court_id": "integer",
  "start_time": "ISO8601 string",
  "end_time": "ISO8601 string",
  "notes": "string|null",
  "payment_method": "string|null",
  "payment_status": "string|null"
}
```

**Notes:**
- `user_id` is optional. If omitted, authenticated user is used.
- Customers cannot create bookings for other users.
- Staff can create bookings (walk-ins) for specific users or without user_id.

**Response Data:** Same as GET /api/v0/bookings/:id

**Status Codes:** 201 Created, 401 Unauthorized, 422 Unprocessable Entity

---

### PATCH /api/v0/bookings/:id

Update booking details.

**Requires:** Authentication (owner/staff only)

**Request Body:**
```json
{
  "court_id": "integer|null",
  "start_time": "ISO8601 string|null",
  "end_time": "ISO8601 string|null",
  "notes": "string|null",
  "payment_method": "string|null",
  "payment_status": "string|null"
}
```

**Response Data:** Same as GET /api/v0/bookings/:id

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden, 422 Unprocessable Entity

---

### PATCH /api/v0/bookings/:id/confirm

Confirm a pending booking.

**Requires:** Authentication (owner/staff only)

**Response Data:** Same as GET /api/v0/bookings/:id

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden, 422 Unprocessable Entity

---

### PATCH /api/v0/bookings/:id/cancel

Cancel a booking.

**Requires:** Authentication

**Request Body:**
```json
{
  "cancellation_reason": "string|null"
}
```

**Response Data:** Same as GET /api/v0/bookings/:id

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden, 422 Unprocessable Entity

---

### PATCH /api/v0/bookings/:id/check_in

Mark a booking as checked in.

**Requires:** Authentication (staff/owner only)

**Response Data:** Same as GET /api/v0/bookings/:id

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### PATCH /api/v0/bookings/:id/no_show

Mark a booking as no-show.

**Requires:** Authentication (staff/owner only)

**Response Data:** Same as GET /api/v0/bookings/:id

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### PATCH /api/v0/bookings/:id/complete

Mark a booking as completed.

**Requires:** Authentication (staff/owner only)

**Response Data:** Same as GET /api/v0/bookings/:id

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### PATCH /api/v0/bookings/:id/reschedule

Reschedule a booking to a different time/court.

**Requires:** Authentication (customer can reschedule own; staff/owner can reschedule any)

**Request Body:**
```json
{
  "court_id": "integer|null",
  "start_time": "ISO8601 string",
  "end_time": "ISO8601 string"
}
```

**Response Data:** Same as GET /api/v0/bookings/:id

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden, 422 Unprocessable Entity

---

### DELETE /api/v0/bookings/:id

Delete a booking (admin only or owner).

**Requires:** Authentication (owner only)

**Response Data:**
```json
{
  "message": "Booking deleted successfully"
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### POST /api/v0/bookings/availability

Check if a court slot is available.

**Request Body:**
```json
{
  "court_id": "integer",
  "start_time": "ISO8601 string",
  "end_time": "ISO8601 string",
  "exclude_booking_id": "integer|null"
}
```

**Response Data:**
```json
{
  "available": "boolean",
  "reason": "string|null"
}
```

**Status Codes:** 200 OK, 422 Unprocessable Entity

---

## 10. Reviews & Ratings

### GET /api/v0/reviews

List reviews.

**Query Params:**
- `page` (optional): integer, default: 1
- `per_page` (optional): integer, default: 20
- `venue_id` (optional): integer
- `court_id` (optional): integer
- `user_id` (optional): integer
- `rating` (optional): integer (1-5)
- `sort` (optional): `created_at`, `rating`
- `order` (optional): `asc`, `desc`

**Response Data:**
```json
[
  {
    "id": "integer",
    "booking_id": "integer",
    "user_id": "integer",
    "user_name": "string",
    "user_avatar_url": "string|null",
    "venue_id": "integer",
    "venue_name": "string",
    "court_id": "integer",
    "court_name": "string",
    "rating": "integer (1-5)",
    "title": "string|null",
    "comment": "string|null",
    "images": [
      {
        "id": "integer",
        "url": "string"
      }
    ],
    "owner_reply": {
      "id": "integer",
      "reply_text": "string",
      "replied_at": "ISO8601 string"
    } | null,
    "created_at": "ISO8601 string",
    "updated_at": "ISO8601 string"
  }
]
```

**Status Codes:** 200 OK

---

### GET /api/v0/reviews/:id

Get review details.

**Response Data:** Same as list item

**Status Codes:** 200 OK, 404 Not Found

---

### POST /api/v0/reviews

Create a new review for a booking.

**Requires:** Authentication (customer only, for own bookings)

**Request Body:**
```json
{
  "booking_id": "integer",
  "rating": "integer (1-5)",
  "title": "string|null",
  "comment": "string|null"
}
```

**Response Data:** Same as GET /api/v0/reviews/:id

**Status Codes:** 201 Created, 401 Unauthorized, 422 Unprocessable Entity

---

### PATCH /api/v0/reviews/:id

Update a review.

**Requires:** Authentication (author only)

**Request Body:**
```json
{
  "rating": "integer (1-5)|null",
  "title": "string|null",
  "comment": "string|null"
}
```

**Response Data:** Same as GET /api/v0/reviews/:id

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden, 422 Unprocessable Entity

---

### DELETE /api/v0/reviews/:id

Delete a review.

**Requires:** Authentication (author only)

**Response Data:**
```json
{
  "message": "Review deleted successfully"
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### POST /api/v0/reviews/:id/reply

Add owner reply to a review.

**Requires:** Authentication (venue owner only)

**Request Body:**
```json
{
  "reply_text": "string"
}
```

**Response Data:**
```json
{
  "id": "integer",
  "reply_text": "string",
  "replied_at": "ISO8601 string"
}
```

**Status Codes:** 201 Created, 401 Unauthorized, 403 Forbidden, 422 Unprocessable Entity

---

### PATCH /api/v0/reviews/:id/reply

Update owner reply.

**Requires:** Authentication (venue owner only)

**Request Body:**
```json
{
  "reply_text": "string"
}
```

**Response Data:** Same as POST reply

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### DELETE /api/v0/reviews/:id/reply

Delete owner reply.

**Requires:** Authentication (venue owner only)

**Response Data:**
```json
{
  "message": "Reply deleted successfully"
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### POST /api/v0/reviews/:id/images

Upload images for a review (multipart).

**Requires:** Authentication (review author only)

**Form Data:**
- `images` (files, multiple): Image files (max 5 files, 5MB each, supported: jpg, jpeg, png, webp)

**Response Data:**
```json
{
  "images": [
    {
      "id": "integer",
      "url": "string"
    }
  ]
}
```

**Status Codes:** 201 Created, 401 Unauthorized, 413 Payload Too Large

---

### DELETE /api/v0/reviews/:id/images/:image_id

Delete an image from review.

**Requires:** Authentication (review author only)

**Response Data:**
```json
{
  "message": "Image deleted successfully"
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### GET /api/v0/venues/:id/review_summary

Get review summary for venue.

**Response Data:**
```json
{
  "venue_id": "integer",
  "average_rating": "number",
  "total_reviews": "integer",
  "rating_distribution": {
    "5": "integer",
    "4": "integer",
    "3": "integer",
    "2": "integer",
    "1": "integer"
  }
}
```

**Status Codes:** 200 OK, 404 Not Found

---

## 11. Staff Management

### GET /api/v0/staff

List all staff members for a venue.

**Query Params:**
- `venue_id` (required): integer
- `status` (optional): `active`, `pending`, `inactive`
- `page` (optional): integer, default: 1
- `per_page` (optional): integer, default: 20

**Requires:** Authentication (owner only)

**Response Data:**
```json
[
  {
    "id": "integer",
    "user_id": "integer",
    "user_name": "string",
    "user_email": "string",
    "user_phone": "string|null",
    "venue_id": "integer",
    "status": "active|pending|inactive",
    "invite_sent_at": "ISO8601 string|null",
    "joined_at": "ISO8601 string|null",
    "created_at": "ISO8601 string"
  }
]
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### POST /api/v0/staff/invite

Send staff invitation via email.

**Requires:** Authentication (owner only)

**Request Body:**
```json
{
  "venue_id": "integer",
  "email": "string"
}
```

**Response Data:**
```json
{
  "id": "integer",
  "email": "string",
  "status": "pending",
  "invite_sent_at": "ISO8601 string"
}
```

**Status Codes:** 201 Created, 401 Unauthorized, 403 Forbidden, 422 Unprocessable Entity

---

### POST /api/v0/staff/bulk_invite

Send multiple staff invitations at once.

**Requires:** Authentication (owner only)

**Request Body:**
```json
{
  "venue_id": "integer",
  "emails": ["string", "string", ...]
}
```

**Response Data:**
```json
{
  "created_count": "integer",
  "failed_count": "integer",
  "staff_members": [...]
}
```

**Status Codes:** 201 Created, 401 Unauthorized, 422 Unprocessable Entity

---

### POST /api/v0/staff/:id/activate

Activate a pending staff member (after they join platform).

**Requires:** Authentication (owner only)

**Response Data:**
```json
{
  "id": "integer",
  "status": "active",
  "joined_at": "ISO8601 string"
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### DELETE /api/v0/staff/:id

Remove a staff member.

**Requires:** Authentication (owner only)

**Response Data:**
```json
{
  "message": "Staff member removed successfully"
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### POST /api/v0/staff/accept_invite

Accept staff invitation (when invited staff joins platform).

**Requires:** Authentication

**Request Body:**
```json
{
  "invite_token": "string"
}
```

**Response Data:**
```json
{
  "message": "Invite accepted successfully",
  "venue": {
    "id": "integer",
    "name": "string"
  }
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 422 Unprocessable Entity

---

## 12. Court Closures & Maintenance

### GET /api/v0/court_closures

List court closures (ad-hoc maintenance).

**Query Params:**
- `venue_id` (optional): integer
- `court_id` (optional): integer
- `from_date` (optional): YYYY-MM-DD
- `to_date` (optional): YYYY-MM-DD
- `page` (optional): integer, default: 1
- `per_page` (optional): integer, default: 20

**Requires:** Authentication (owner only)

**Response Data:**
```json
[
  {
    "id": "integer",
    "court_id": "integer",
    "court_name": "string",
    "venue_id": "integer",
    "reason": "string",
    "start_time": "ISO8601 string",
    "end_time": "ISO8601 string",
    "created_by_id": "integer",
    "created_by_name": "string",
    "created_at": "ISO8601 string",
    "updated_at": "ISO8601 string"
  }
]
```

**Status Codes:** 200 OK, 401 Unauthorized

---

### POST /api/v0/court_closures

Create a court closure/maintenance window.

**Requires:** Authentication (owner/staff only)

**Request Body:**
```json
{
  "court_id": "integer",
  "reason": "string",
  "start_time": "ISO8601 string",
  "end_time": "ISO8601 string"
}
```

**Response Data:** Same as list item

**Status Codes:** 201 Created, 401 Unauthorized, 422 Unprocessable Entity

---

### PATCH /api/v0/court_closures/:id

Update a court closure.

**Requires:** Authentication (owner/staff only)

**Request Body:**
```json
{
  "reason": "string|null",
  "start_time": "ISO8601 string|null",
  "end_time": "ISO8601 string|null"
}
```

**Response Data:** Same as list item

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden, 422 Unprocessable Entity

---

### DELETE /api/v0/court_closures/:id

Delete a court closure.

**Requires:** Authentication (owner/staff only)

**Response Data:**
```json
{
  "message": "Court closure deleted successfully"
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

## 13. Media & Images

### POST /api/v0/venues/:id/images

Upload images for a venue (multipart).

**Requires:** Authentication (owner only)

**Form Data:**
- `images` (files, multiple): Image files (max 10 files for venue, 5MB each)

**Response Data:**
```json
{
  "images": [
    {
      "id": "integer",
      "url": "string",
      "alt_text": "string|null",
      "display_order": "integer"
    }
  ]
}
```

**Status Codes:** 201 Created, 401 Unauthorized, 413 Payload Too Large

---

### PATCH /api/v0/venues/:id/images/:image_id

Update image details (alt text, reorder).

**Requires:** Authentication (owner only)

**Request Body:**
```json
{
  "alt_text": "string|null",
  "display_order": "integer|null"
}
```

**Response Data:**
```json
{
  "id": "integer",
  "url": "string",
  "alt_text": "string|null",
  "display_order": "integer"
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### DELETE /api/v0/venues/:id/images/:image_id

Delete venue image.

**Requires:** Authentication (owner only)

**Response Data:**
```json
{
  "message": "Image deleted successfully"
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### POST /api/v0/venues/:id/images/reorder

Reorder venue images.

**Requires:** Authentication (owner only)

**Request Body:**
```json
{
  "image_ids": ["integer", "integer", ...]
}
```

**Response Data:**
```json
{
  "images": [
    {
      "id": "integer",
      "display_order": "integer"
    }
  ]
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### POST /api/v0/courts/:id/images

Upload images for a court (multipart).

**Requires:** Authentication (owner only)

**Form Data:**
- `images` (files, multiple): Image files (max 8 files per court, 5MB each)

**Response Data:**
```json
{
  "images": [
    {
      "id": "integer",
      "url": "string",
      "alt_text": "string|null",
      "display_order": "integer"
    }
  ]
}
```

**Status Codes:** 201 Created, 401 Unauthorized, 413 Payload Too Large

---

### PATCH /api/v0/courts/:id/images/:image_id

Update court image details.

**Requires:** Authentication (owner only)

**Request Body:**
```json
{
  "alt_text": "string|null",
  "display_order": "integer|null"
}
```

**Response Data:** Same as venue image response

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### DELETE /api/v0/courts/:id/images/:image_id

Delete court image.

**Requires:** Authentication (owner only)

**Response Data:**
```json
{
  "message": "Image deleted successfully"
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### POST /api/v0/courts/:id/images/reorder

Reorder court images.

**Requires:** Authentication (owner only)

**Request Body:**
```json
{
  "image_ids": ["integer", "integer", ...]
}
```

**Response Data:** Same as venue reorder

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

## 14. Reports & Analytics

### GET /api/v0/reports/bookings

Get booking statistics for venue.

**Query Params:**
- `venue_id` (required): integer
- `from_date` (required): YYYY-MM-DD
- `to_date` (required): YYYY-MM-DD
- `court_id` (optional): integer
- `group_by` (optional): `day`, `week`, `month`, `court` (default: day)

**Requires:** Authentication (owner only)

**Response Data:**
```json
{
  "venue_id": "integer",
  "period": {
    "from": "YYYY-MM-DD",
    "to": "YYYY-MM-DD"
  },
  "summary": {
    "total_bookings": "integer",
    "confirmed_bookings": "integer",
    "pending_bookings": "integer",
    "cancelled_bookings": "integer",
    "completed_bookings": "integer",
    "no_show_count": "integer"
  },
  "data": [
    {
      "date": "YYYY-MM-DD",
      "court_name": "string|null",
      "bookings_count": "integer",
      "confirmed_count": "integer",
      "cancelled_count": "integer"
    }
  ]
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### GET /api/v0/reports/revenue

Get revenue statistics for venue.

**Query Params:**
- `venue_id` (required): integer
- `from_date` (required): YYYY-MM-DD
- `to_date` (required): YYYY-MM-DD
- `court_id` (optional): integer
- `group_by` (optional): `day`, `week`, `month`, `court` (default: day)

**Requires:** Authentication (owner only)

**Response Data:**
```json
{
  "venue_id": "integer",
  "period": {
    "from": "YYYY-MM-DD",
    "to": "YYYY-MM-DD"
  },
  "summary": {
    "total_revenue": "number",
    "estimated_revenue": "number",
    "completed_revenue": "number",
    "currency": "string"
  },
  "data": [
    {
      "date": "YYYY-MM-DD",
      "court_name": "string|null",
      "bookings": "integer",
      "revenue": "number"
    }
  ]
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### GET /api/v0/reports/occupancy

Get court occupancy rates.

**Query Params:**
- `venue_id` (required): integer
- `from_date` (required): YYYY-MM-DD
- `to_date` (required): YYYY-MM-DD

**Requires:** Authentication (owner only)

**Response Data:**
```json
{
  "venue_id": "integer",
  "period": {
    "from": "YYYY-MM-DD",
    "to": "YYYY-MM-DD"
  },
  "data": [
    {
      "court_id": "integer",
      "court_name": "string",
      "total_slots": "integer",
      "booked_slots": "integer",
      "occupancy_rate": "number (0-100)"
    }
  ]
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### GET /api/v0/reports/peak_hours

Get peak booking hours heatmap data.

**Query Params:**
- `venue_id` (required): integer
- `from_date` (required): YYYY-MM-DD
- `to_date` (required): YYYY-MM-DD

**Requires:** Authentication (owner only)

**Response Data:**
```json
{
  "venue_id": "integer",
  "data": [
    {
      "hour": "integer (0-23)",
      "day_of_week": "integer (0-6)",
      "day_name": "string",
      "bookings_count": "integer",
      "percentage": "number"
    }
  ]
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### GET /api/v0/reports/cancellations

Get cancellation statistics.

**Query Params:**
- `venue_id` (required): integer
- `from_date` (required): YYYY-MM-DD
- `to_date` (required): YYYY-MM-DD
- `court_id` (optional): integer

**Requires:** Authentication (owner only)

**Response Data:**
```json
{
  "venue_id": "integer",
  "total_cancellations": "integer",
  "cancellation_rate": "number (0-100)",
  "reasons": [
    {
      "reason": "string",
      "count": "integer"
    }
  ]
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### GET /api/v0/reports/staff_activity

Get staff member activity and stats.

**Query Params:**
- `venue_id` (required): integer
- `from_date` (required): YYYY-MM-DD
- `to_date` (required): YYYY-MM-DD

**Requires:** Authentication (owner only)

**Response Data:**
```json
{
  "venue_id": "integer",
  "staff_members": [
    {
      "staff_id": "integer",
      "staff_name": "string",
      "bookings_created": "integer",
      "bookings_confirmed": "integer",
      "bookings_cancelled": "integer"
    }
  ]
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### GET /api/v0/reports/export

Export reports as CSV/PDF.

**Query Params:**
- `type` (required): `bookings`, `revenue`, `occupancy`
- `venue_id` (required): integer
- `from_date` (required): YYYY-MM-DD
- `to_date` (required): YYYY-MM-DD
- `format` (optional): `csv`, `pdf` (default: csv)

**Requires:** Authentication (owner only)

**Response:** File download (CSV or PDF)

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

## 15. Audit Logs

### GET /api/v0/audit_logs

Get audit logs for venue.

**Query Params:**
- `venue_id` (required): integer
- `entity_type` (optional): `booking`, `court`, `pricing_rule`, `staff`, `venue`
- `action` (optional): `created`, `updated`, `deleted`, `confirmed`, `cancelled`
- `user_id` (optional): integer
- `from_date` (optional): YYYY-MM-DD
- `to_date` (optional): YYYY-MM-DD
- `page` (optional): integer, default: 1
- `per_page` (optional): integer, default: 50

**Requires:** Authentication (owner only)

**Response Data:**
```json
[
  {
    "id": "integer",
    "venue_id": "integer",
    "entity_type": "string",
    "entity_id": "integer",
    "entity_name": "string",
    "action": "created|updated|deleted|confirmed|cancelled",
    "user_id": "integer",
    "user_name": "string",
    "user_role": "owner|staff",
    "changes": {
      "field_name": {
        "old_value": "string|number|null",
        "new_value": "string|number|null"
      }
    },
    "ip_address": "string|null",
    "created_at": "ISO8601 string"
  }
]
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### GET /api/v0/audit_logs/:id

Get specific audit log entry.

**Requires:** Authentication (owner only)

**Response Data:** Same as list item

**Status Codes:** 200 OK, 401 Unauthorized, 404 Not Found

---

### GET /api/v0/audit_logs/export

Export audit logs as CSV.

**Query Params:**
- `venue_id` (required): integer
- `from_date` (optional): YYYY-MM-DD
- `to_date` (optional): YYYY-MM-DD
- `format` (optional): `csv` (always CSV for audit logs)

**Requires:** Authentication (owner only)

**Response:** CSV file download

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

## 16. Shareable Links & Public Pages

### POST /api/v0/bookings/:id/generate_share_link

Generate a shareable link for a booking.

**Requires:** Authentication (booking user only)

**Response Data:**
```json
{
  "share_link": "string",
  "short_code": "string"
}
```

**Status Codes:** 200 OK, 401 Unauthorized, 403 Forbidden

---

### GET /api/v0/share/:short_code

Get public booking details (no authentication required).

**Path Params:**
- `short_code` (required): string

**Response Data:**
```json
{
  "booking_id": "integer",
  "booking_status": "string",
  "court_name": "string",
  "venue_name": "string",
  "start_time": "ISO8601 string",
  "end_time": "ISO8601 string",
  "duration_minutes": "integer",
  "booked_by": "string",
  "can_install_app": "boolean",
  "app_store_url": "string|null",
  "play_store_url": "string|null"
}
```

**Status Codes:** 200 OK, 404 Not Found

---

### GET /api/v0/courts/:id/qr_code

Generate QR code for a court (encodes court info).

**Query Params:**
- `format` (optional): `svg`, `png` (default: svg)

**Response Data:**
```json
{
  "qr_code_url": "string",
  "qr_code_data": "string"
}
```

Or returns image file if format is png.

**Status Codes:** 200 OK, 404 Not Found

---

### GET /api/v0/qr/:code

Get public court page from QR code (no authentication).

**Path Params:**
- `code` (required): string

**Response Data:**
```json
{
  "court_id": "integer",
  "court_name": "string",
  "venue_name": "string",
  "sport_type": "string",
  "city": "string",
  "images": ["string"],
  "rating": "number|null",
  "available_today": "boolean",
  "can_install_app": "boolean",
  "app_store_url": "string|null",
  "play_store_url": "string|null"
}
```

**Status Codes:** 200 OK, 404 Not Found

---

## 17. User Preferences & Settings

### GET /api/v0/preferences

Get user preferences.

**Requires:** Authentication

**Response Data:**
```json
{
  "user_id": "integer",
  "preferred_city_id": "integer|null",
  "preferred_city_name": "string|null",
  "preferred_area_id": "integer|null",
  "preferred_area_name": "string|null",
  "notification_day_reminder": "boolean",
  "notification_30min_reminder": "boolean",
  "notification_marketing": "boolean",
  "preferred_language": "string",
  "theme_preference": "light|dark|auto",
  "created_at": "ISO8601 string",
  "updated_at": "ISO8601 string"
}
```

**Status Codes:** 200 OK, 401 Unauthorized

---

### PATCH /api/v0/preferences

Update user preferences.

**Requires:** Authentication

**Request Body:**
```json
{
  "preferred_city_id": "integer|null",
  "preferred_area_id": "integer|null",
  "notification_day_reminder": "boolean|null",
  "notification_30min_reminder": "boolean|null",
  "notification_marketing": "boolean|null",
  "preferred_language": "string|null",
  "theme_preference": "light|dark|auto|null"
}
```

**Response Data:** Same as GET

**Status Codes:** 200 OK, 401 Unauthorized, 422 Unprocessable Entity

---

### DELETE /api/v0/preferences

Reset preferences to defaults.

**Requires:** Authentication

**Response Data:**
```json
{
  "message": "Preferences reset to defaults"
}
```

**Status Codes:** 200 OK, 401 Unauthorized

---

## 18. Error Responses

### Standard Error Response Format

```json
{
  "success": false,
  "errors": [
    "Field validation error or descriptive message"
  ]
}
```

### Common HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request succeeded |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid request parameters |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Authenticated but not authorized |
| 404 | Not Found | Resource not found |
| 422 | Unprocessable Entity | Validation errors |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |
| 503 | Service Unavailable | Service temporarily unavailable |

### Authentication Error

```json
{
  "success": false,
  "errors": [
    "Unauthorized access",
    "Invalid or expired token"
  ]
}
```

### Validation Error

```json
{
  "success": false,
  "errors": [
    "Email has already been taken",
    "Password is too short (minimum 8 characters)"
  ]
}
```

### Rate Limit Error

```json
{
  "success": false,
  "errors": [
    "Rate limit exceeded. Please try again later."
  ]
}
```

---

## Implementation Notes

### For Frontend Teams

1. **Authentication Flow:**
   - Use `/api/v0/auth/signup` or OAuth endpoints for registration
   - Use `/api/v0/auth/signin` for login
   - Store `access_token` and `refresh_token` securely
   - Include authorization header on all requests: `Authorization: Bearer <access_token>`
   - Use `/api/v0/auth/refresh` to refresh tokens when expired

2. **Error Handling:**
   - Always check `success` field first
   - Parse `errors` array for user-facing error messages
   - Implement retry logic for 5xx errors
   - Handle 401 by refreshing token or redirecting to login

3. **Pagination:**
   - Use `page` and `per_page` query parameters for listing endpoints
   - Response includes `pagination` object with total count
   - Frontend should implement infinite scroll or pagination UI

4. **Date/Time Handling:**
   - All dates are ISO8601 format with UTC timezone
   - Convert to user's local timezone on frontend
   - Dates: `YYYY-MM-DD`, Times: `YYYY-MM-DDTHH:MM:SSZ`

5. **Caching:**
   - Cache cities and sports lists (low change frequency)
   - Don't cache user-specific data (bookings, preferences)
   - Invalidate venue/court caches when updated

6. **Deep Linking:**
   - Use share links format: `booktruf.com/share/<short_code>`
   - Use QR links format: `booktruf.com/qr/<code>`
   - Mobile apps should intercept these URLs

---

## Version History

- **v1.0** (April 2026): Initial comprehensive reference based on product spec
  - Includes all customer, owner, and staff endpoints
  - Full OAuth integration
  - Reports and audit logging
  - Media management

---

**Document Status:** Draft - Ready for Frontend Team
**Last Updated:** April 16, 2026
**Maintainer:** Development Team
