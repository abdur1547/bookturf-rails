# API v0: Venue Management Endpoints

**Version**: 1.0  
**Base URL**: `/api/v0`  
**Authentication**: Optional for INDEX, Required for other operations  
**Authorization**: Pundit policies  
**Last Updated**: 2026-04-13

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication & Authorization](#authentication--authorization)
3. [Common Response Formats](#common-response-formats)
4. [Venues Endpoints](#venues-endpoints)
   - [List Venues](#list-venues)
   - [Get Venue](#get-venue)
   - [Create Venue](#create-venue)
   - [Update Venue](#update-venue)
   - [Delete Venue](#delete-venue)
5. [Nested Attributes](#nested-attributes)
6. [Validation Rules](#validation-rules)
7. [Business Logic Services](#business-logic-services)
8. [Operations Architecture](#operations-architecture)
9. [Blueprint Serialization](#blueprint-serialization)
10. [Implementation Checklist](#implementation-checklist)

---

## Overview

This document describes the REST API endpoints for managing venues in the Bookturf application.

### Key Features

- **Full CRUD Operations**: Create, read, update, and delete venues
- **Nested Attributes**: Update venue settings and operating hours in single request
- **Public Listing**: No authentication required for listing venues
- **Authorization Levels**: Owner (full), Admin (update), Staff/Receptionist (read-only), Customer (read-only)
- **Immutable Fields**: `owner_id`, `slug`, and `created_at` cannot be changed after creation
- **Smart Validation**: Operating hours overlap detection, dependency checks before deletion
- **Google Maps Integration**: Manual lat/lng input with URL generation

---

## Authentication & Authorization

### Authentication Requirements

| Endpoint | Authentication |
|----------|----------------|
| `GET /api/v0/venues` | **Optional** - Public endpoint |
| `GET /api/v0/venues/:id` | Optional - Public endpoint |
| `POST /api/v0/venues` | **Required** - Must be authenticated user |
| `PATCH/PUT /api/v0/venues/:id` | **Required** - Owner or Admin |
| `DELETE /api/v0/venues/:id` | **Required** - Owner only |

### Authorization Matrix

| Role | List | View | Create | Update | Delete |
|------|------|------|--------|--------|--------|
| **Public** | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Customer** | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Staff/Receptionist** | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Admin** | ✅ | ✅ | ✅ | ✅ | ❌ |
| **Owner** | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Global Admin** | ✅ | ✅ | ✅ | ✅ | ✅ |

**Notes**:
- Customers can create venues (becoming the owner)
- Only venue owner can delete their venue
- Admins can update but not delete venues

---

## Common Response Formats

### Success Response

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Sports Arena Karachi",
    ...
  }
}
```

### Success with Pagination (List)

```json
{
  "success": true,
  "data": [
    { "id": 1, "name": "Venue 1", ... },
    { "id": 2, "name": "Venue 2", ... }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 48,
    "per_page": 10
  }
}
```

### Error Response

```json
{
  "success": false,
  "errors": [
    {
      "field": "name",
      "message": "can't be blank"
    }
  ]
}
```

### Validation Error Response

```json
{
  "success": false,
  "errors": [
    {
      "field": "venue_operating_hours",
      "message": "Operating hours overlap detected for Monday"
    },
    {
      "field": "latitude",
      "message": "must be between -90 and 90"
    }
  ]
}
```

---

## Venues Endpoints

### List Venues

Get a paginated list of all active venues.

**Endpoint**: `GET /api/v0/venues`  
**Authentication**: Optional (public endpoint)  
**Authorization**: None required

#### Request

**Query Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `page` | integer | No | Page number (default: 1) |
| `per_page` | integer | No | Items per page (default: 10, max: 100) |
| `city` | string | No | Filter by city |
| `state` | string | No | Filter by state |
| `country` | string | No | Filter by country |
| `is_active` | boolean | No | Filter by active status (default: true) |
| `search` | string | No | Search in name, address, city |
| `sort` | string | No | Sort field: `name`, `city`, `created_at` (default: `name`) |
| `order` | string | No | Sort order: `asc`, `desc` (default: `asc`) |

**Example**:
```http
GET /api/v0/venues?city=Karachi&page=1&per_page=20&sort=name&order=asc
```

#### Response: 200 OK

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Sports Arena Karachi",
      "slug": "sports-arena-karachi",
      "description": "Premier sports facility...",
      "address": "Plot 123, Block 5, Clifton",
      "city": "Karachi",
      "state": "Sindh",
      "country": "Pakistan",
      "postal_code": "75600",
      "latitude": 24.8175,
      "longitude": 67.0297,
      "google_maps_url": "https://www.google.com/maps?q=24.8175,67.0297",
      "phone_number": "+92 21 35123456",
      "email": "info@sportsarena.pk",
      "is_active": true,
      "courts_count": 6,
      "created_at": "2026-01-15T10:30:00Z",
      "owner": {
        "id": 1,
        "first_name": "Ahmed",
        "last_name": "Khan",
        "email": "owner@example.com"
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 3,
    "total_count": 28,
    "per_page": 10
  }
}
```

---

### Get Venue

Get detailed information about a specific venue.

**Endpoint**: `GET /api/v0/venues/:id`  
**Authentication**: Optional  
**Authorization**: None required

#### Request

**URL Parameters**:
- `id` (integer or string) - Venue ID or slug

**Example**:
```http
GET /api/v0/venues/1
GET /api/v0/venues/sports-arena-karachi
```

#### Response: 200 OK

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Sports Arena Karachi",
    "slug": "sports-arena-karachi",
    "description": "Premier sports facility in Karachi with badminton, tennis, and basketball courts",
    "address": "Plot 123, Block 5, Clifton",
    "city": "Karachi",
    "state": "Sindh",
    "country": "Pakistan",
    "postal_code": "75600",
    "latitude": 24.8175,
    "longitude": 67.0297,
    "google_maps_url": "https://www.google.com/maps?q=24.8175,67.0297",
    "phone_number": "+92 21 35123456",
    "email": "info@sportsarena.pk",
    "is_active": true,
    "courts_count": 6,
    "created_at": "2026-01-15T10:30:00Z",
    "updated_at": "2026-04-10T14:20:00Z",
    "owner": {
      "id": 1,
      "first_name": "Ahmed",
      "last_name": "Khan",
      "email": "owner@example.com",
      "phone_number": "+92 300 1234567"
    },
    "venue_setting": {
      "id": 1,
      "minimum_slot_duration": 60,
      "maximum_slot_duration": 180,
      "slot_interval": 30,
      "advance_booking_days": 30,
      "requires_approval": false,
      "cancellation_hours": 24,
      "timezone": "Asia/Karachi",
      "currency": "PKR"
    },
    "venue_operating_hours": [
      {
        "id": 1,
        "day_of_week": 0,
        "day_name": "Sunday",
        "opens_at": "08:00:00",
        "closes_at": "00:00:00",
        "is_closed": false,
        "formatted_hours": "08:00 AM - 12:00 AM"
      },
      {
        "id": 2,
        "day_of_week": 1,
        "day_name": "Monday",
        "opens_at": "09:00:00",
        "closes_at": "23:00:00",
        "is_closed": false,
        "formatted_hours": "09:00 AM - 11:00 PM"
      },
      {
        "id": 3,
        "day_of_week": 2,
        "day_name": "Tuesday",
        "opens_at": "09:00:00",
        "closes_at": "23:00:00",
        "is_closed": false,
        "formatted_hours": "09:00 AM - 11:00 PM"
      },
      {
        "id": 4,
        "day_of_week": 3,
        "day_name": "Wednesday",
        "opens_at": "09:00:00",
        "closes_at": "23:00:00",
        "is_closed": false,
        "formatted_hours": "09:00 AM - 11:00 PM"
      },
      {
        "id": 5,
        "day_of_week": 4,
        "day_name": "Thursday",
        "opens_at": "09:00:00",
        "closes_at": "23:00:00",
        "is_closed": false,
        "formatted_hours": "09:00 AM - 11:00 PM"
      },
      {
        "id": 6,
        "day_of_week": 5,
        "day_name": "Friday",
        "opens_at": "09:00:00",
        "closes_at": "23:00:00",
        "is_closed": false,
        "formatted_hours": "09:00 AM - 11:00 PM"
      },
      {
        "id": 7,
        "day_of_week": 6,
        "day_name": "Saturday",
        "opens_at": "08:00:00",
        "closes_at": "00:00:00",
        "is_closed": false,
        "formatted_hours": "08:00 AM - 12:00 AM"
      }
    ]
  }
}
```

#### Error Responses

**404 Not Found**:
```json
{
  "success": false,
  "errors": [
    {
      "message": "Venue not found"
    }
  ]
}
```

---

### Create Venue

Create a new venue. The authenticated user becomes the venue owner.

**Endpoint**: `POST /api/v0/venues`  
**Authentication**: Required  
**Authorization**: Any authenticated user can create a venue (becomes owner)

#### Request

**Headers**:
```
Content-Type: application/json
Authorization: Bearer <access_token>
```

**Body Parameters**:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | string | Yes | Venue name (3-100 chars) |
| `description` | text | No | Venue description |
| `address` | text | Yes | Physical address |
| `city` | string | No | City |
| `state` | string | No | State/Province |
| `country` | string | No | Country |
| `postal_code` | string | No | Postal/ZIP code |
| `latitude` | decimal | No | GPS latitude (-90 to 90) |
| `longitude` | decimal | No | GPS longitude (-180 to 180) |
| `phone_number` | string | No | Contact phone |
| `email` | string | No | Contact email |
| `venue_setting` | object | No | Venue settings (see below) |
| `venue_operating_hours` | array | No | Operating hours for 7 days (see below) |

**Venue Setting Object** (optional):

```json
{
  "minimum_slot_duration": 60,
  "maximum_slot_duration": 180,
  "slot_interval": 30,
  "advance_booking_days": 30,
  "requires_approval": false,
  "cancellation_hours": 24,
  "timezone": "Asia/Karachi",
  "currency": "PKR"
}
```

**Venue Operating Hours Array** (optional - defaults to 9 AM - 11 PM all days):

```json
[
  {
    "day_of_week": 0,
    "opens_at": "08:00",
    "closes_at": "23:00",
    "is_closed": false
  },
  {
    "day_of_week": 1,
    "opens_at": "09:00",
    "closes_at": "23:00",
    "is_closed": false
  },
  // ... 5 more days (total 7)
]
```

**Example Request**:

```json
{
  "name": "Sports Arena Karachi",
  "description": "Premier sports facility in Karachi",
  "address": "Plot 123, Block 5, Clifton",
  "city": "Karachi",
  "state": "Sindh",
  "country": "Pakistan",
  "postal_code": "75600",
  "latitude": 24.8175,
  "longitude": 67.0297,
  "phone_number": "+92 21 35123456",
  "email": "info@sportsarena.pk",
  "venue_setting": {
    "minimum_slot_duration": 60,
    "maximum_slot_duration": 180,
    "slot_interval": 30,
    "advance_booking_days": 30,
    "timezone": "Asia/Karachi",
    "currency": "PKR"
  },
  "venue_operating_hours": [
    { "day_of_week": 0, "opens_at": "08:00", "closes_at": "23:00", "is_closed": false },
    { "day_of_week": 1, "opens_at": "09:00", "closes_at": "23:00", "is_closed": false },
    { "day_of_week": 2, "opens_at": "09:00", "closes_at": "23:00", "is_closed": false },
    { "day_of_week": 3, "opens_at": "09:00", "closes_at": "23:00", "is_closed": false },
    { "day_of_week": 4, "opens_at": "09:00", "closes_at": "23:00", "is_closed": false },
    { "day_of_week": 5, "opens_at": "09:00", "closes_at": "23:00", "is_closed": false },
    { "day_of_week": 6, "opens_at": "08:00", "closes_at": "23:00", "is_closed": false }
  ]
}
```

#### Response: 201 Created

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Sports Arena Karachi",
    "slug": "sports-arena-karachi",
    // ... full venue details (same as GET response)
  }
}
```

#### Error Responses

**422 Unprocessable Entity** (validation errors):

```json
{
  "success": false,
  "errors": [
    {
      "field": "name",
      "message": "can't be blank"
    },
    {
      "field": "address",
      "message": "can't be blank"
    },
    {
      "field": "latitude",
      "message": "must be between -90 and 90"
    },
    {
      "field": "venue_operating_hours",
      "message": "must have exactly 7 days (one for each day of week)"
    }
  ]
}
```

**401 Unauthorized** (not authenticated):

```json
{
  "success": false,
  "errors": [
    {
      "message": "You must be logged in to perform this action"
    }
  ]
}
```

---

### Update Venue

Update an existing venue and optionally its settings and operating hours.

**Endpoint**: `PATCH /api/v0/venues/:id` or `PUT /api/v0/venues/:id`  
**Authentication**: Required  
**Authorization**: Owner or Admin

#### Request

**URL Parameters**:
- `id` (integer or string) - Venue ID or slug

**Headers**:
```
Content-Type: application/json
Authorization: Bearer <access_token>
```

**Body Parameters**: Same as CREATE, but all optional. Send only fields to update.

**Immutable Fields** (will be ignored if sent):
- `owner_id` - Cannot change ownership
- `slug` - Cannot change slug after creation
- `created_at` - System managed

**Example Request** (partial update):

```json
{
  "name": "Updated Sports Arena",
  "phone_number": "+92 21 99999999",
  "venue_setting": {
    "advance_booking_days": 45,
    "cancellation_hours": 48
  },
  "venue_operating_hours": [
    { "day_of_week": 0, "opens_at": "10:00", "closes_at": "22:00", "is_closed": false },
    { "day_of_week": 1, "opens_at": "09:00", "closes_at": "23:00", "is_closed": false },
    { "day_of_week": 2, "opens_at": "09:00", "closes_at": "23:00", "is_closed": false },
    { "day_of_week": 3, "opens_at": "09:00", "closes_at": "23:00", "is_closed": false },
    { "day_of_week": 4, "opens_at": "09:00", "closes_at": "23:00", "is_closed": false },
    { "day_of_week": 5, "opens_at": "09:00", "closes_at": "23:00", "is_closed": false },
    { "day_of_week": 6, "opens_at": "10:00", "closes_at": "22:00", "is_closed": false }
  ]
}
```

#### Response: 200 OK

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Updated Sports Arena",
    // ... full updated venue details
  }
}
```

#### Error Responses

**403 Forbidden** (not authorized):

```json
{
  "success": false,
  "errors": [
    {
      "message": "You are not authorized to perform this action"
    }
  ]
}
```

**422 Unprocessable Entity** (validation error):

```json
{
  "success": false,
  "errors": [
    {
      "field": "venue_operating_hours",
      "message": "Cannot deactivate venue while active bookings exist"
    }
  ]
}
```

**404 Not Found**:

```json
{
  "success": false,
  "errors": [
    {
      "message": "Venue not found"
    }
  ]
}
```

---

### Delete Venue

Permanently delete a venue. Only allowed if no dependencies exist (courts, bookings, etc.).

**Endpoint**: `DELETE /api/v0/venues/:id`  
**Authentication**: Required  
**Authorization**: Owner only

#### Request

**URL Parameters**:
- `id` (integer or string) - Venue ID or slug

**Headers**:
```
Authorization: Bearer <access_token>
```

**Example**:
```http
DELETE /api/v0/venues/1
```

#### Response: 200 OK

```json
{
  "success": true,
  "data": {
    "message": "Venue successfully deleted"
  }
}
```

#### Error Responses

**403 Forbidden** (not owner):

```json
{
  "success": false,
  "errors": [
    {
      "message": "Only venue owner can delete the venue"
    }
  ]
}
```

**422 Unprocessable Entity** (has dependencies):

```json
{
  "success": false,
  "errors": [
    {
      "message": "Cannot delete venue with existing courts. Please delete all courts first."
    }
  ]
}
```

Alternative error if bookings exist:

```json
{
  "success": false,
  "errors": [
    {
      "message": "Cannot delete venue with existing bookings"
    }
  ]
}
```

**404 Not Found**:

```json
{
  "success": false,
  "errors": [
    {
      "message": "Venue not found"
    }
  ]
}
```

---

## Nested Attributes

### Venue Settings

When creating/updating a venue, you can include `venue_setting` as a nested object. If not provided, defaults will be used.

**Default Values**:
- `minimum_slot_duration`: 60 minutes
- `maximum_slot_duration`: 180 minutes
- `slot_interval`: 30 minutes
- `advance_booking_days`: 30 days
- `requires_approval`: false
- `cancellation_hours`: null
- `timezone`: "Asia/Karachi"
- `currency`: "PKR"

**Validation**:
- `maximum_slot_duration` must be >= `minimum_slot_duration`
- All duration values must be positive
- `slot_interval` must be divisible into `minimum_slot_duration`

### Venue Operating Hours

When creating/updating venue, you can include `venue_operating_hours` as an array of 7 objects (one for each day).

**Requirements**:
- Must provide exactly 7 days (day_of_week: 0-6, where 0 = Sunday)
- All 7 days must be present (no partial updates)
- `closes_at` must be after `opens_at`
- If `is_closed: true`, `opens_at` and `closes_at` are optional

**Example of closed day**:

```json
{
  "day_of_week": 2,
  "is_closed": true
}
```

---

## Validation Rules

### Model-Level Validations

From `app/models/venue.rb`:

- `name`: Required, 3-100 characters
- `slug`: Required, unique, lowercase alphanumeric with hyphens only
- `address`: Required
- `phone_number`: Valid phone format (allows spaces, hyphens, parentheses)
- `email`: Valid email format (if provided)
- `latitude`: Between -90 and 90 (if provided)
- `longitude`: Between -180 and 180 (if provided)

### Business Logic Validations

Implemented in Operations/Services:

1. **Operating Hours Validation**:
   - No overlapping hours within same day (although rare, checks `closes_at` > `opens_at`)
   - All 7 days must be provided when updating
   - `is_closed` days don't require `opens_at`/`closes_at`

2. **Deactivation Prevention**:
   - Cannot set `is_active: false` if active bookings exist for this venue
   - Must cancel or complete all bookings first

3. **Latitude/Longitude Requirement for Activation**:
   - If setting `is_active: true`, both `latitude` and `longitude` must be present
   - Ensures venue has proper location before going live

4. **Deletion Restrictions**:
   - Cannot delete if any courts exist
   - Cannot delete if any bookings exist
   - Must clean up dependencies first

5. **Immutable Fields**:
   - `owner_id` cannot be changed after creation
   - `slug` cannot be changed after creation (auto-generated from name)
   - `created_at` is system-managed

---

## Business Logic Services

Following the architecture pattern, business logic will be split between Services (reusable) and Operations (controller orchestration).

### Services Layer

**File**: `app/services/venues/venue_creator_service.rb`

```ruby
class Venues::VenueCreatorService < BaseService
  def call(venue_params:, owner:)
    venue = Venue.new(venue_params.except(:venue_setting, :venue_operating_hours))
    venue.owner = owner
    
    if venue.save
      success(venue: venue)
    else
      failure(venue.errors)
    end
  end
end
```

**File**: `app/services/venues/venue_updater_service.rb`

```ruby
class Venues::VenueUpdaterService < BaseService
  def call(venue:, venue_params:)
    # Remove immutable fields
    sanitized_params = venue_params.except(:owner_id, :slug, :created_at)
    
    if venue.update(sanitized_params)
      success(venue: venue)
    else
      failure(venue.errors)
    end
  end
end
```

**File**: `app/services/venues/venue_destroyer_service.rb`

```ruby
class Venues::VenueDestroyerService < BaseService
  def call(venue:)
    return failure("Cannot delete venue with existing courts") if venue.courts.any?
    return failure("Cannot delete venue with existing bookings") if venue.bookings.any?
    
    if venue.destroy
      success(message: "Venue successfully deleted")
    else
      failure(venue.errors)
    end
  end
end
```

**File**: `app/services/venues/operating_hours_validator_service.rb`

```ruby
class Venues::OperatingHoursValidatorService < BaseService
  def call(operating_hours:)
    return failure("Must provide exactly 7 days") unless operating_hours.size == 7
    
    # Validate each day
    (0..6).each do |day|
      day_hours = operating_hours.find { |h| h[:day_of_week] == day }
      return failure("Missing hours for day #{day}") unless day_hours
      
      next if day_hours[:is_closed]
      
      # Validate opens_at and closes_at
      if day_hours[:closes_at] <= day_hours[:opens_at]
        return failure("Closes time must be after opens time for day #{day}")
      end
    end
    
    success(valid: true)
  end
end
```

**File**: `app/services/venues/venue_activation_validator_service.rb`

```ruby
class Venues::VenueActivationValidatorService < BaseService
  def call(venue:, is_active:)
    return success(valid: true) unless is_active
    
    # If activating, require lat/lng
    if venue.latitude.blank? || venue.longitude.blank?
      return failure("Latitude and longitude required to activate venue")
    end
    
    success(valid: true)
  end
end
```

---

## Operations Architecture

### File Structure

```
app/operations/api/v0/venues/
  ├── list_venues_operation.rb
  ├── get_venue_operation.rb
  ├── create_venue_operation.rb
  ├── update_venue_operation.rb
  └── delete_venue_operation.rb
```

### List Venues Operation

**File**: `app/operations/api/v0/venues/list_venues_operation.rb`

```ruby
# frozen_string_literal: true

module Api::V0::Venues
  class ListVenuesOperation < BaseOperation
    contract do
      params do
        optional(:page).maybe(:integer)
        optional(:per_page).maybe(:integer)
        optional(:city).maybe(:string)
        optional(:state).maybe(:string)
        optional(:country).maybe(:string)
        optional(:is_active).maybe(:bool)
        optional(:search).maybe(:string)
        optional(:sort).maybe(:string)
        optional(:order).maybe(:string)
      end
      
      rule(:per_page) do
        key.failure("must be between 1 and 100") if value && (value < 1 || value > 100)
      end
      
      rule(:sort) do
        valid_sorts = %w[name city created_at]
        key.failure("must be one of: #{valid_sorts.join(', ')}") if value && !valid_sorts.include?(value)
      end
      
      rule(:order) do
        key.failure("must be 'asc' or 'desc'") if value && !%w[asc desc].include?(value)
      end
    end

    def call(params, current_user = nil)
      @params = params
      @current_user = current_user
      
      # Public endpoint - no authorization required
      
      @venues = fetch_venues
      @venues = apply_filters(@venues)
      @venues = apply_search(@venues)
      @venues = apply_sorting(@venues)
      @venues = paginate(@venues)
      
      json_data = serialize
      
      Success(
        venues: @venues,
        json: json_data,
        meta: pagination_meta
      )
    end

    private

    attr_reader :params, :current_user, :venues

    def fetch_venues
      Venue.includes(:owner, :venue_setting, :venue_operating_hours)
    end

    def apply_filters(venues)
      venues = venues.where(city: params[:city]) if params[:city].present?
      venues = venues.where(state: params[:state]) if params[:state].present?
      venues = venues.where(country: params[:country]) if params[:country].present?
      venues = venues.where(is_active: params[:is_active]) if params.key?(:is_active)
      venues
    end

    def apply_search(venues)
      return venues if params[:search].blank?
      
      search_term = "%#{params[:search]}%"
      venues.where(
        "name ILIKE ? OR address ILIKE ? OR city ILIKE ?",
        search_term, search_term, search_term
      )
    end

    def apply_sorting(venues)
      sort_field = params[:sort] || "name"
      order = params[:order] || "asc"
      
      venues.order("#{sort_field} #{order}")
    end

    def paginate(venues)
      page = params[:page] || 1
      per_page = params[:per_page] || 10
      
      @pagy, paginated_venues = pagy(venues, page: page, items: per_page)
      paginated_venues
    end

    def serialize
      Api::V0::VenueBlueprint.render_as_hash(venues, view: :list)
    end

    def pagination_meta
      {
        current_page: @pagy.page,
        total_pages: @pagy.pages,
        total_count: @pagy.count,
        per_page: @pagy.items
      }
    end
  end
end
```

### Get Venue Operation

**File**: `app/operations/api/v0/venues/get_venue_operation.rb`

```ruby
# frozen_string_literal: true

module Api::V0::Venues
  class GetVenueOperation < BaseOperation
    contract do
      params do
        required(:id).filled
      end
    end

    def call(params, current_user = nil)
      @params = params
      @current_user = current_user
      
      # Public endpoint - no authorization required
      
      @venue = find_venue
      return Failure(:not_found) unless @venue
      
      json_data = serialize
      Success(venue: @venue, json: json_data)
    end

    private

    attr_reader :params, :current_user, :venue

    def find_venue
      Venue
        .includes(:owner, :venue_setting, :venue_operating_hours)
        .find_by(id: params[:id]) ||
      Venue
        .includes(:owner, :venue_setting, :venue_operating_hours)
        .find_by(slug: params[:id])
    end

    def serialize
      Api::V0::VenueBlueprint.render_as_hash(venue, view: :detailed)
    end
  end
end
```

### Create Venue Operation

**File**: `app/operations/api/v0/venues/create_venue_operation.rb`

```ruby
# frozen_string_literal: true

module Api::V0::Venues
  class CreateVenueOperation < BaseOperation
    contract do
      params do
        required(:name).filled(:string)
        required(:address).filled(:string)
        optional(:description).maybe(:string)
        optional(:city).maybe(:string)
        optional(:state).maybe(:string)
        optional(:country).maybe(:string)
        optional(:postal_code).maybe(:string)
        optional(:latitude).maybe(:float)
        optional(:longitude).maybe(:float)
        optional(:phone_number).maybe(:string)
        optional(:email).maybe(:string)
        optional(:venue_setting).maybe(:hash)
        optional(:venue_operating_hours).maybe(:array)
      end
      
      rule(:latitude) do
        key.failure("must be between -90 and 90") if value && (value < -90 || value > 90)
      end
      
      rule(:longitude) do
        key.failure("must be between -180 and 180") if value && (value < -180 || value > 180)
      end
      
      rule(:venue_operating_hours) do
        if value.present?
          key.failure("must have exactly 7 days") unless value.size == 7
        end
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user
      
      return Failure(:unauthorized) unless authorize?
      
      # Validate operating hours if provided
      if params[:venue_operating_hours].present?
        validation = Venues::OperatingHoursValidatorService.call(
          operating_hours: params[:venue_operating_hours]
        )
        return Failure(validation.error) unless validation.success?
      end
      
      # Validate activation requirements
      if params[:is_active]
        validation = Venues::VenueActivationValidatorService.call(
          venue: Venue.new(params.slice(:latitude, :longitude)),
          is_active: true
        )
        return Failure(validation.error) unless validation.success?
      end
      
      # Create venue
      result = Venues::VenueCreatorService.call(
        venue_params: params,
        owner: current_user
      )
      
      return Failure(result.error) unless result.success?
      
      venue = result.data[:venue]
      
      # Create nested attributes
      create_venue_setting(venue) if params[:venue_setting].present?
      create_operating_hours(venue) if params[:venue_operating_hours].present?
      
      # Reload to get associations
      venue.reload
      
      json_data = serialize(venue)
      Success(venue: venue, json: json_data)
    end

    private

    attr_reader :params, :current_user

    def authorize?
      current_user.present?
    end

    def create_venue_setting(venue)
      venue.create_venue_setting!(params[:venue_setting])
    end

    def create_operating_hours(venue)
      params[:venue_operating_hours].each do |hours_params|
        venue.venue_operating_hours.create!(hours_params)
      end
    end

    def serialize(venue)
      Api::V0::VenueBlueprint.render_as_hash(venue, view: :detailed)
    end
  end
end
```

### Update Venue Operation

**File**: `app/operations/api/v0/venues/update_venue_operation.rb`

```ruby
# frozen_string_literal: true

module Api::V0::Venues
  class UpdateVenueOperation < BaseOperation
    contract do
      params do
        required(:id).filled
        optional(:name).maybe(:string)
        optional(:description).maybe(:string)
        optional(:address).maybe(:string)
        optional(:city).maybe(:string)
        optional(:state).maybe(:string)
        optional(:country).maybe(:string)
        optional(:postal_code).maybe(:string)
        optional(:latitude).maybe(:float)
        optional(:longitude).maybe(:float)
        optional(:phone_number).maybe(:string)
        optional(:email).maybe(:string)
        optional(:is_active).maybe(:bool)
        optional(:venue_setting).maybe(:hash)
        optional(:venue_operating_hours).maybe(:array)
      end
      
      rule(:latitude) do
        key.failure("must be between -90 and 90") if value && (value < -90 || value > 90)
      end
      
      rule(:longitude) do
        key.failure("must be between -180 and 180") if value && (value < -180 || value > 180)
      end
      
      rule(:venue_operating_hours) do
        if value.present?
          key.failure("must have exactly 7 days") unless value.size == 7
        end
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user
      
      @venue = find_venue
      return Failure(:not_found) unless @venue
      
      return Failure(:unauthorized) unless authorize?
      
      # Validate deactivation
      if params.key?(:is_active) && !params[:is_active]
        return Failure("Cannot deactivate venue while active bookings exist") if has_active_bookings?
      end
      
      # Validate activation requirements
      if params[:is_active]
        validation = Venues::VenueActivationValidatorService.call(
          venue: @venue,
          is_active: true
        )
        return Failure(validation.error) unless validation.success?
      end
      
      # Validate operating hours if provided
      if params[:venue_operating_hours].present?
        validation = Venues::OperatingHoursValidatorService.call(
          operating_hours: params[:venue_operating_hours]
        )
        return Failure(validation.error) unless validation.success?
      end
      
      # Update venue
      result = Venues::VenueUpdaterService.call(
        venue: @venue,
        venue_params: params
      )
      
      return Failure(result.error) unless result.success?
      
      # Update nested attributes
      update_venue_setting if params[:venue_setting].present?
      update_operating_hours if params[:venue_operating_hours].present?
      
      # Reload to get updated associations
      @venue.reload
      
      json_data = serialize
      Success(venue: @venue, json: json_data)
    end

    private

    attr_reader :params, :current_user, :venue

    def find_venue
      Venue.includes(:owner, :venue_setting, :venue_operating_hours)
           .find_by(id: params[:id]) ||
      Venue.includes(:owner, :venue_setting, :venue_operating_hours)
           .find_by(slug: params[:id])
    end

    def authorize?
      VenuePolicy.new(current_user, venue).update?
    end

    def has_active_bookings?
      venue.bookings.where(status: ['confirmed', 'checked_in']).exists?
    end

    def update_venue_setting
      if venue.venue_setting
        venue.venue_setting.update!(params[:venue_setting])
      else
        venue.create_venue_setting!(params[:venue_setting])
      end
    end

    def update_operating_hours
      # Delete existing and recreate (replace all)
      venue.venue_operating_hours.destroy_all
      
      params[:venue_operating_hours].each do |hours_params|
        venue.venue_operating_hours.create!(hours_params)
      end
    end

    def serialize
      Api::V0::VenueBlueprint.render_as_hash(venue, view: :detailed)
    end
  end
end
```

### Delete Venue Operation

**File**: `app/operations/api/v0/venues/delete_venue_operation.rb`

```ruby
# frozen_string_literal: true

module Api::V0::Venues
  class DeleteVenueOperation < BaseOperation
    contract do
      params do
        required(:id).filled
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user
      
      @venue = find_venue
      return Failure(:not_found) unless @venue
      
      return Failure(:unauthorized) unless authorize?
      
      # Delete venue via service
      result = Venues::VenueDestroyerService.call(venue: @venue)
      
      return Failure(result.error) unless result.success?
      
      Success(message: "Venue successfully deleted")
    end

    private

    attr_reader :params, :current_user, :venue

    def find_venue
      Venue.find_by(id: params[:id]) || Venue.find_by(slug: params[:id])
    end

    def authorize?
      VenuePolicy.new(current_user, venue).destroy?
    end
  end
end
```

---

## Blueprint Serialization

### File Structure

```
app/blueprints/api/v0/
  ├── venue_blueprint.rb
  ├── venue_setting_blueprint.rb
  └── venue_operating_hour_blueprint.rb
```

### Venue Blueprint

**File**: `app/blueprints/api/v0/venue_blueprint.rb`

```ruby
# frozen_string_literal: true

module Api::V0
  class VenueBlueprint < BaseBlueprint
    identifier :id

    fields :name, :slug, :description, :address, :city, :state, :country,
           :postal_code, :latitude, :longitude, :phone_number, :email,
           :is_active, :created_at

    field :google_maps_url do |venue|
      venue.google_maps_url
    end

    field :courts_count do |venue|
      venue.courts.count
    end

    association :owner, blueprint: Api::V0::UserBlueprint, view: :minimal do |venue|
      venue.owner
    end

    # List view - for index endpoint
    view :list do
      fields :id, :name, :slug, :description, :address, :city, :state,
             :country, :postal_code, :latitude, :longitude, :google_maps_url,
             :phone_number, :email, :is_active, :courts_count, :created_at

      association :owner, blueprint: Api::V0::UserBlueprint, view: :minimal
    end

    # Detailed view - for show, create, update endpoints
    view :detailed do
      fields :id, :name, :slug, :description, :address, :city, :state,
             :country, :postal_code, :latitude, :longitude, :google_maps_url,
             :phone_number, :email, :is_active, :courts_count,
             :created_at, :updated_at

      association :owner, blueprint: Api::V0::UserBlueprint, view: :detailed do |venue|
        venue.owner
      end

      association :venue_setting, blueprint: Api::V0::VenueSettingBlueprint do |venue|
        venue.venue_setting
      end

      association :venue_operating_hours, blueprint: Api::V0::VenueOperatingHourBlueprint do |venue|
        venue.venue_operating_hours.order(:day_of_week)
      end
    end

    # Minimal view - for nested associations in other resources
    view :minimal do
      fields :id, :name, :slug, :city
    end
  end
end
```

### Venue Setting Blueprint

**File**: `app/blueprints/api/v0/venue_setting_blueprint.rb`

```ruby
# frozen_string_literal: true

module Api::V0
  class VenueSettingBlueprint < BaseBlueprint
    identifier :id

    fields :minimum_slot_duration, :maximum_slot_duration, :slot_interval,
           :advance_booking_days, :requires_approval, :cancellation_hours,
           :timezone, :currency
  end
end
```

### Venue Operating Hour Blueprint

**File**: `app/blueprints/api/v0/venue_operating_hour_blueprint.rb`

```ruby
# frozen_string_literal: true

module Api::V0
  class VenueOperatingHourBlueprint < BaseBlueprint
    identifier :id

    fields :day_of_week, :opens_at, :closes_at, :is_closed

    field :day_name do |hour|
      hour.day_name
    end

    field :formatted_hours do |hour|
      hour.formatted_hours
    end
  end
end
```

---

## Controller Implementation

**File**: `app/controllers/api/v0/venues_controller.rb`

```ruby
# frozen_string_literal: true

module Api::V0
  class VenuesController < ApiController
    skip_before_action :authenticate_user!, only: [:index, :show]

    # GET /api/v0/venues
    def index
      result = Api::V0::Venues::ListVenuesOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # GET /api/v0/venues/:id
    def show
      result = Api::V0::Venues::GetVenueOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # POST /api/v0/venues
    def create
      result = Api::V0::Venues::CreateVenueOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result, :created)
    end

    # PATCH/PUT /api/v0/venues/:id
    def update
      result = Api::V0::Venues::UpdateVenueOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # DELETE /api/v0/venues/:id
    def destroy
      result = Api::V0::Venues::DeleteVenueOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    private

    def handle_operation_response(result, success_status = :ok)
      if result.success
        render json: {
          success: true,
          data: result.value[:json],
          meta: result.value[:meta]
        }.compact, status: success_status
      else
        handle_operation_failure(result)
      end
    end

    def handle_operation_failure(result)
      errors = result.errors

      case errors
      when :unauthorized
        forbidden_response("You are not authorized to perform this action")
      when :not_found
        not_found_response("Venue not found")
      else
        unprocessable_entity(errors)
      end
    end
  end
end
```

---

## Pundit Policy

**File**: `app/policies/venue_policy.rb`

```ruby
# frozen_string_literal: true

class VenuePolicy < ApplicationPolicy
  def index?
    true # Public endpoint
  end

  def show?
    true # Public endpoint
  end

  def create?
    user.present? # Any authenticated user can create venue
  end

  def update?
    return true if user.is_global_admin?
    return true if user.id == record.owner_id # Owner
    return true if user.has_role?('admin') # Admin
    false
  end

  def destroy?
    return true if user.is_global_admin?
    return true if user.id == record.owner_id # Only owner
    false
  end

  class Scope < Scope
    def resolve
      scope.all # Show all venues (public)
    end
  end
end
```

---

## Routes Configuration

**File**: `config/routes/api_v0.rb`

```ruby
# Add to existing routes:

namespace :api do
  namespace :v0 do
    # ... existing routes ...
    
    resources :venues, only: API_ONLY_ROUTES
  end
end
```

---

## Implementation Checklist

### Phase 1: Models & Database (Already Complete ✅)
- [x] Venue model with associations
- [x] VenueSetting model
- [x] VenueOperatingHour model
- [x] Database migrations
- [x] Model validations
- [x] Seed data

### Phase 2: Services (Business Logic)
- [ ] Create `Venues::VenueCreatorService`
- [ ] Create `Venues::VenueUpdaterService`
- [ ] Create `Venues::VenueDestroyerService`
- [ ] Create `Venues::OperatingHoursValidatorService`
- [ ] Create `Venues::VenueActivationValidatorService`
- [ ] Write service specs

### Phase 3: Operations (Controller Orchestration)
- [ ] Create `Api::V0::Venues::ListVenuesOperation`
- [ ] Create `Api::V0::Venues::GetVenueOperation`
- [ ] Create `Api::V0::Venues::CreateVenueOperation`
- [ ] Create `Api::V0::Venues::UpdateVenueOperation`
- [ ] Create `Api::V0::Venues::DeleteVenueOperation`
- [ ] Write operation specs

### Phase 4: Blueprints (Serialization)
- [ ] Create `Api::V0::VenueBlueprint` with views: list, detailed, minimal
- [ ] Create `Api::V0::VenueSettingBlueprint`
- [ ] Create `Api::V0::VenueOperatingHourBlueprint`
- [ ] Test blueprint outputs

### Phase 5: Controllers
- [ ] Create `Api::V0::VenuesController`
- [ ] Implement all CRUD actions
- [ ] Add authentication/authorization
- [ ] Proper error handling

### Phase 6: Authorization (Pundit Policies)
- [ ] Create `VenuePolicy`
- [ ] Implement `index?`, `show?`, `create?`, `update?`, `destroy?`
- [ ] Test policy rules

### Phase 7: Routes
- [ ] Add venue resources to `config/routes/api_v0.rb`
- [ ] Test route paths

### Phase 8: Request Specs (Integration Tests)
- [ ] `spec/requests/api/v0/venues_spec.rb`
- [ ] Test all endpoints with various scenarios:
  - Success paths (authenticated/unauthenticated)
  - Authorization (different roles)
  - Validation errors
  - Not found errors
  - Edge cases
- [ ] Test nested attributes (venue_setting, venue_operating_hours)
- [ ] Test filters, search, pagination
- [ ] Test immutable fields

### Phase 9: Documentation & Review
- [ ] Update API documentation
- [ ] Postman/Insomnia collection
- [ ] Frontend integration guide
- [ ] Code review

---

## Testing Strategy

### Service Specs

**File**: `spec/services/venues/venue_creator_service_spec.rb`

```ruby
require 'rails_helper'

RSpec.describe Venues::VenueCreatorService do
  let(:owner) { create(:user) }
  
  describe '#call' do
    context 'with valid params' do
      let(:venue_params) do
        {
          name: 'Test Venue',
          address: '123 Test St',
          city: 'Karachi'
        }
      end
      
      it 'creates a venue successfully' do
        result = described_class.call(venue_params: venue_params, owner: owner)
        
        expect(result).to be_success
        expect(result.data[:venue]).to be_a(Venue)
        expect(result.data[:venue].name).to eq('Test Venue')
        expect(result.data[:venue].owner).to eq(owner)
      end
    end
    
    context 'with invalid params' do
      let(:venue_params) { { name: '' } }
      
      it 'returns failure with errors' do
        result = described_class.call(venue_params: venue_params, owner: owner)
        
        expect(result).to be_failure
      end
    end
  end
end
```

### Request Specs

**File**: `spec/requests/api/v0/venues_spec.rb`

Follow the pattern from [REQUEST_SPECS_BEST_PRACTICES.md](REQUEST_SPECS_BEST_PRACTICES.md).

Test structure:
```ruby
describe "GET /api/v0/venues" do
  # SUCCESS PATHS
  context "when requesting venue list" do
    it "returns all active venues"
    it "returns venues with pagination"
    it "filters by city"
    it "searches venues by name"
  end
  
  # FAILURE PATHS
  context "with invalid query params" do
    it "returns error for invalid per_page"
  end
end

describe "POST /api/v0/venues" do
  # SUCCESS PATHS
  context "when authenticated as user" do
    it "creates venue successfully"
    it "creates venue with nested attributes"
  end
  
  # FAILURE PATHS
  context "when not authenticated" do
    it "returns 401 unauthorized"
  end
  
  context "with invalid params" do
    it "returns validation errors"
  end
end
```

---

## Next Steps

1. **Implement Services** - Start with basic CRUD services
2. **Create Operations** - Add validation and orchestration logic
3. **Build Blueprints** - Define JSON response structures
4. **Wire Controllers** - Connect operations to endpoints
5. **Add Policies** - Implement authorization rules
6. **Write Tests** - Comprehensive test coverage
7. **Document** - Update API docs and create examples
8. **Frontend Integration** - Connect Angular app

---

## Related Documentation

- [Database Schema](SCHEMA.md)
- [Database Phase 2: Venues](DB_PHASE_2_VENUES.md)
- [Operations Pattern](OPERATIONS.md)
- [Service Objects](SERVICE_OBJECTS.md)
- [Blueprinter Usage](BLUEPRINTER_USAGE.md)
- [Request Specs Best Practices](REQUEST_SPECS_BEST_PRACTICES.md)
- [Pundit Setup](PUNDIT_SETUP.md)

---

*Last Updated: 2026-04-13*  
*Version: 1.0*
