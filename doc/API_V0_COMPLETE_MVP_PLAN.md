# Bookturf MVP - Complete API Endpoints Plan

**Version**: 1.0 (MVP)  
**Base URL**: `/api/v0`  
**Authentication**: JWT (Bearer token or HTTP-only cookies)  
**Created**: 2026-04-13  

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Implementation Priority](#implementation-priority)
3. [Authentication Status Legend](#authentication-status-legend)
4. [Complete Endpoint List](#complete-endpoint-list)
5. [Resource Details](#resource-details)
   - [1. Authentication (✅ Implemented)](#1-authentication--implemented)
   - [2. Roles (✅ Implemented)](#2-roles--implemented)
   - [3. Users](#3-users)
   - [4. Permissions](#4-permissions)
   - [5. User Roles](#5-user-roles)
   - [6. Venues](#6-venues)
   - [7. Court Types](#7-court-types)
   - [8. Courts](#8-courts)
   - [9. Pricing Rules](#9-pricing-rules)
   - [10. Bookings](#10-bookings)
   - [11. Court Closures](#11-court-closures)
   - [12. Notifications](#12-notifications)
   - [13. Dashboard & Stats](#13-dashboard--stats)
6. [Authorization Matrix](#authorization-matrix)
7. [Search & Filter Capabilities](#search--filter-capabilities)
8. [Implementation Checklist](#implementation-checklist)
9. [API Response Standards](#api-response-standards)
10. [Testing Requirements](#testing-requirements)

---

## Overview

This document provides a complete plan for all API endpoints required for the Bookturf MVP. The API follows RESTful principles and is organized around business resources.

### Design Principles

1. **Operations-First**: All business logic in Operations layer
2. **Service Objects**: Reusable business logic
3. **Pundit Authorization**: Policy-based access control
4. **Blueprinter Serialization**: Consistent JSON responses
5. **Venue Scoping**: All resources scoped to venue (except public endpoints)
6. **Audit Logging**: Track all changes (booking logs, etc.)

### MVP Constraints

- **Single Venue**: Each owner has one venue
- **Cash Payments**: No online payment gateway integration
- **In-App Notifications**: No email/SMS notifications
- **Manual Lat/Lng**: No geocoding API for venue location

---

## Implementation Priority

### Phase A: Foundation (Week 1)
Priority: Complete before other phases

1. **Users** - User management for owner/admin
2. **Permissions** - List permissions for role assignment
3. **User Roles** - Assign roles to users in venue

### Phase B: Venue Setup (Week 1-2)
Priority: Core infrastructure

4. **Venues** - Venue CRUD with nested settings/hours
5. **Court Types** - Read-only list of pre-seeded types
6. **Courts** - CRUD for venue courts
7. **Pricing Rules** - Time-based pricing setup

### Phase C: Core Booking (Week 2-3)
Priority: Primary business feature

8. **Bookings** - Full CRUD + special operations
   - Availability check
   - Price calculation
   - Cancel, Check-in, No-show, Complete, Reschedule

### Phase D: Operations Support (Week 3-4)
Priority: Supporting features

9. **Court Closures** - Maintenance scheduling
10. **Notifications** - In-app notifications
11. **Dashboard** - Stats and analytics

---

## Authentication Status Legend

- ✅ **Implemented** - Already built and working
- 🟡 **Partial** - Documented but not implemented
- ⚪ **Planned** - Needs implementation

---

## Complete Endpoint List

### Summary by Resource

| Resource | Status | Endpoints | Public | Auth Required | Notes |
|----------|--------|-----------|--------|---------------|-------|
| **Authentication** | ✅ | 6 | Some | Some | Signup, signin, signout, refresh, password reset |
| **Roles** | ✅ | 5 | No | Yes | Full CRUD implemented |
| **Users** | 🟡 | 7 | No | Yes | Documented, not implemented |
| **Permissions** | ⚪ | 1 | No | Yes | List only (for role assignment) |
| **User Roles** | ⚪ | 2 | No | Yes | Assign/remove roles |
| **Venues** | 🟡 | 5 | Some | Some | Documented, not implemented |
| **Court Types** | ⚪ | 1 | Yes | No | Read-only list |
| **Courts** | ⚪ | 5 | Some | Some | Full CRUD |
| **Pricing Rules** | ⚪ | 5 | No | Yes | Full CRUD |
| **Bookings** | ⚪ | 10 | No | Yes | CRUD + 5 special actions |
| **Court Closures** | ⚪ | 5 | No | Yes | Full CRUD |
| **Notifications** | ⚪ | 4 | No | Yes | List, read, mark all read |
| **Dashboard** | ⚪ | 3 | No | Yes | Stats for owner/admin |

**Total Endpoints**: 59

---

## Resource Details

---

## 1. Authentication (✅ Implemented)

**Status**: ✅ Complete  
**Base Path**: `/api/v0/auth`  
**Controllers**: `Api::V0::AuthController`  
**Operations**: 6 operations in `app/operations/api/v0/auth/`  

### Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/auth/signup` | ❌ | Register new user |
| `POST` | `/auth/signin` | ❌ | Login with email/password |
| `DELETE` | `/auth/signout` | ✅ | Logout and invalidate tokens |
| `POST` | `/auth/refresh` | ✅ | Refresh access token |
| `POST` | `/auth/reset_password` | ❌ | Request password reset (send OTP) |
| `POST` | `/auth/verify_reset_otp` | ❌ | Verify OTP and reset password |

**Implementation**: Already complete with operations, controller, and tests.

---

## 2. Roles (✅ Implemented)

**Status**: ✅ Complete  
**Base Path**: `/api/v0/roles`  
**Controllers**: `Api::V0::RolesController`  
**Operations**: 5 operations in `app/operations/api/v0/roles/`  
**Blueprint**: `Api::V0::RoleBlueprint`  

### Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/roles` | ✅ | List all roles (system + custom) |
| `GET` | `/roles/:id` | ✅ | Get role details with permissions |
| `POST` | `/roles` | ✅ | Create custom role |
| `PATCH/PUT` | `/roles/:id` | ✅ | Update role (name, permissions) |
| `DELETE` | `/roles/:id` | ✅ | Delete custom role |

**Implementation**: Already complete with full CRUD operations, policies, and tests.

**Query Params for List**:
- `is_custom` - Filter by custom/system roles
- `page` - Pagination

**Authorization**:
- List: Owner, Admin, Receptionist
- Show: Owner, Admin, Receptionist
- Create: Owner only
- Update: Owner only
- Delete: Owner only (cannot delete system roles)

---

## 3. Users

**Status**: 🟡 Partial (Documented but not implemented)  
**Base Path**: `/api/v0/users`  
**Planned Controller**: `Api::V0::UsersController`  
**Operations Needed**: 7 operations  
**Blueprint Needed**: `Api::V0::UserBlueprint` (already exists)  

### Endpoints

| Method | Path | Auth | Description | Operation |
|--------|------|------|-------------|-----------|
| `GET` | `/users` | ✅ | List users in venue | `ListUsersOperation` |
| `GET` | `/users/:id` | ✅ | Get user details | `GetUserOperation` |
| `GET` | `/users/me` | ✅ | Get current user profile | `GetCurrentUserOperation` |
| `POST` | `/users` | ✅ | Create user (add staff/customer) | `CreateUserOperation` |
| `PATCH/PUT` | `/users/:id` | ✅ | Update user profile | `UpdateUserOperation` |
| `PATCH` | `/users/:id/activate` | ✅ | Activate user account | `ActivateUserOperation` |
| `PATCH` | `/users/:id/deactivate` | ✅ | Deactivate user account | `DeactivateUserOperation` |

### Query Params for List (`GET /users`)

```
?role=customer               # Filter by role (owner, admin, receptionist, staff, customer)
?is_active=true             # Filter by active status
?search=john                # Search by name or email
?page=1                     # Pagination
?per_page=20                # Items per page
```

### Request Body - Create User (`POST /users`)

```json
{
  "user": {
    "email": "receptionist@example.com",
    "password": "Password123!",
    "password_confirmation": "Password123!",
    "first_name": "Ahmed",
    "last_name": "Khan",
    "phone_number": "+92 300 1234567",
    "role_ids": [3]  // Assign role(s) immediately
  }
}
```

### Request Body - Update User (`PATCH /users/:id`)

```json
{
  "user": {
    "first_name": "Ahmed",
    "last_name": "Khan",
    "phone_number": "+92 300 1234567",
    "emergency_contact_name": "Fatima Khan",
    "emergency_contact_phone": "+92 300 9876543"
  }
}
```

**Note**: `email` cannot be changed. `password` update requires separate endpoint or current password verification.

### Response - User Object

**View: `:list`**
```json
{
  "id": 15,
  "email": "ahmed.khan@example.com",
  "first_name": "Ahmed",
  "last_name": "Khan",
  "full_name": "Ahmed Khan",
  "phone_number": "+92 300 1234567",
  "is_active": true,
  "roles": [
    { "id": 3, "name": "Receptionist" }
  ],
  "created_at": "2026-04-13T10:30:00Z"
}
```

**View: `:detailed`**
```json
{
  "id": 15,
  "email": "ahmed.khan@example.com",
  "first_name": "Ahmed",
  "last_name": "Khan",
  "full_name": "Ahmed Khan",
  "phone_number": "+92 300 1234567",
  "emergency_contact_name": "Fatima Khan",
  "emergency_contact_phone": "+92 300 9876543",
  "is_active": true,
  "is_global_admin": false,
  "roles": [
    {
      "id": 3,
      "name": "Receptionist",
      "slug": "receptionist",
      "is_custom": false
    }
  ],
  "created_at": "2026-04-13T10:30:00Z",
  "updated_at": "2026-04-13T12:00:00Z"
}
```

### Authorization

| Action | Owner | Admin | Receptionist | Staff | Customer |
|--------|-------|-------|--------------|-------|----------|
| List | ✅ | ✅ | ✅ | ✅ | ❌ |
| Show | ✅ (all) | ✅ (all) | ✅ (all) | ✅ (all) | ✅ (self only) |
| Me | ✅ | ✅ | ✅ | ✅ | ✅ |
| Create | ✅ | ✅ | ❌ | ❌ | ❌ |
| Update | ✅ (all) | ✅ (all) | ❌ | ❌ | ✅ (self only) |
| Activate | ✅ | ✅ | ❌ | ❌ | ❌ |
| Deactivate | ✅ | ✅ | ❌ | ❌ | ❌ |

### Business Rules

1. **Email Uniqueness**: Email must be unique across all venues
2. **Venue Scoping**: List only shows users in current user's venue
3. **Owner Protection**: Cannot deactivate venue owner
4. **Role Assignment**: Must assign at least one valid role on creation
5. **Self Update**: Users can update their own profile (except sensitive fields)

### Services Needed

- `Users::CreateService` - Create user with role assignment
- `Users::UpdateService` - Update user profile
- `Users::ActivateService` - Activate user account
- `Users::DeactivateService` - Deactivate user account

---

## 4. Permissions

**Status**: ⚪ Planned  
**Base Path**: `/api/v0/permissions`  
**Planned Controller**: `Api::V0::PermissionsController`  
**Operations Needed**: 1 operation  
**Blueprint Needed**: `Api::V0::PermissionBlueprint` (already exists)  

### Endpoints

| Method | Path | Auth | Description | Operation |
|--------|------|------|-------------|-----------|
| `GET` | `/permissions` | ✅ | List all permissions | `ListPermissionsOperation` |

**Purpose**: Used by frontend when creating/editing roles to show available permissions.

### Query Params for List

```
?resource=bookings          # Filter by resource (bookings, courts, users, etc.)
?action=create              # Filter by action (create, read, update, delete, manage)
```

### Response

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "create:bookings",
      "resource": "bookings",
      "action": "create",
      "description": "Can create new bookings"
    },
    {
      "id": 2,
      "name": "read:bookings",
      "resource": "bookings",
      "action": "read",
      "description": "Can view bookings"
    }
  ]
}
```

### Authorization

- Owner, Admin: Can list all permissions
- Others: Cannot access

**Note**: Permissions are seeded and not user-editable.

---

## 5. User Roles

**Status**: ⚪ Planned  
**Base Path**: `/api/v0/user_roles`  
**Planned Controller**: `Api::V0::UserRolesController`  
**Operations Needed**: 2 operations  

### Endpoints

| Method | Path | Auth | Description | Operation |
|--------|------|------|-------------|-----------|
| `POST` | `/user_roles` | ✅ | Assign role to user | `AssignRoleOperation` |
| `DELETE` | `/user_roles/:id` | ✅ | Remove role from user | `RemoveRoleOperation` |

**Note**: User roles are also managed when creating/updating users (via nested attributes).

### Request - Assign Role (`POST /user_roles`)

```json
{
  "user_id": 15,
  "role_id": 3
}
```

### Response - Success

```json
{
  "success": true,
  "data": {
    "user_id": 15,
    "role_id": 3,
    "assigned_by": 1,
    "assigned_at": "2026-04-13T10:30:00Z"
  }
}
```

### Request - Remove Role (`DELETE /user_roles/:id`)

Uses `user_role.id` from database.

### Authorization

- Owner, Admin: Can assign/remove roles
- Others: Cannot access

### Business Rules

1. **Venue Scoping**: Can only assign roles to users in same venue
2. **Valid Roles**: Role must exist and be applicable to venue
3. **Duplicate Prevention**: Cannot assign same role twice
4. **Owner Protection**: Cannot remove owner role from venue owner

---

## 6. Venues

**Status**: 🟡 Partial (Documented but not implemented)  
**Base Path**: `/api/v0/venues`  
**Planned Controller**: `Api::V0::VenuesController`  
**Operations Needed**: 5 operations  
**Blueprint Needed**: `Api::V0::VenueBlueprint`  

### Endpoints

| Method | Path | Auth | Description | Operation |
|--------|------|------|-------------|-----------|
| `GET` | `/venues` | ❌ | List venues (public) | `ListVenuesOperation` |
| `GET` | `/venues/:id` | ❌ | Get venue details (public) | `GetVenueOperation` |
| `POST` | `/venues` | ✅ | Create venue | `CreateVenueOperation` |
| `PATCH/PUT` | `/venues/:id` | ✅ | Update venue | `UpdateVenueOperation` |
| `DELETE` | `/venues/:id` | ✅ | Delete venue | `DeleteVenueOperation` |

### Query Params for List (`GET /venues`)

```
?city=Karachi               # Filter by city
?search=sports              # Search by name or description
?page=1                     # Pagination
?per_page=20                # Items per page
```

### Request Body - Create Venue (`POST /venues`)

```json
{
  "venue": {
    "name": "Sports Arena Karachi",
    "address": "123 Main Street, Gulshan-e-Iqbal",
    "city": "Karachi",
    "state": "Sindh",
    "country": "Pakistan",
    "postal_code": "75300",
    "phone_number": "+92 21 1234567",
    "email": "info@sportsarena.pk",
    "latitude": 24.8607,
    "longitude": 67.0011,
    "description": "Premium sports facility with 6 courts",
    
    "venue_setting_attributes": {
      "minimum_slot_duration": 60,
      "maximum_slot_duration": 180,
      "slot_interval": 30,
      "advance_booking_days": 30,
      "timezone": "Asia/Karachi",
      "currency": "PKR",
      "requires_approval": false,
      "cancellation_hours": 24
    },
    
    "venue_operating_hours_attributes": [
      {
        "day_of_week": 0,
        "opens_at": "10:00",
        "closes_at": "20:00",
        "is_closed": false
      },
      {
        "day_of_week": 1,
        "opens_at": "09:00",
        "closes_at": "23:00",
        "is_closed": false
      },
      // ... days 2-6
    ]
  }
}
```

**MVP Rules**:
- `owner_id` is automatically set to `current_user.id`
- User can only have one venue
- `slug` is auto-generated from name
- Operating hours for all 7 days must be provided

### Request Body - Update Venue (`PATCH /venues/:id`)

```json
{
  "venue": {
    "name": "Sports Arena Karachi",
    "phone_number": "+92 21 1234567",
    "description": "Updated description",
    
    "venue_setting_attributes": {
      "id": 1,
      "cancellation_hours": 48
    },
    
    "venue_operating_hours_attributes": [
      {
        "id": 1,
        "opens_at": "08:00",
        "closes_at": "22:00"
      }
    ]
  }
}
```

**Immutable Fields**:
- `owner_id` - Cannot be changed
- `slug` - Cannot be changed (auto-generated on create)

### Response - Venue Object

**View: `:list`** (Public list)
```json
{
  "id": 1,
  "name": "Sports Arena Karachi",
  "slug": "sports-arena-karachi",
  "city": "Karachi",
  "state": "Sindh",
  "country": "Pakistan",
  "address": "123 Main Street, Gulshan-e-Iqbal",
  "phone_number": "+92 21 1234567",
  "email": "info@sportsarena.pk",
  "latitude": 24.8607,
  "longitude": 67.0011,
  "google_maps_url": "https://www.google.com/maps?q=24.8607,67.0011",
  "is_active": true,
  "created_at": "2026-04-01T10:00:00Z"
}
```

**View: `:detailed`** (For owner/admin)
```json
{
  "id": 1,
  "name": "Sports Arena Karachi",
  "slug": "sports-arena-karachi",
  "description": "Premium sports facility",
  "address": "123 Main Street, Gulshan-e-Iqbal",
  "city": "Karachi",
  "state": "Sindh",
  "country": "Pakistan",
  "postal_code": "75300",
  "latitude": 24.8607,
  "longitude": 67.0011,
  "google_maps_url": "https://www.google.com/maps?q=24.8607,67.0011",
  "phone_number": "+92 21 1234567",
  "email": "info@sportsarena.pk",
  "is_active": true,
  
  "owner": {
    "id": 1,
    "first_name": "Muhammad",
    "last_name": "Ali",
    "email": "owner@example.com"
  },
  
  "venue_setting": {
    "id": 1,
    "minimum_slot_duration": 60,
    "maximum_slot_duration": 180,
    "slot_interval": 30,
    "advance_booking_days": 30,
    "timezone": "Asia/Karachi",
    "currency": "PKR",
    "requires_approval": false,
    "cancellation_hours": 24
  },
  
  "venue_operating_hours": [
    {
      "id": 1,
      "day_of_week": 0,
      "day_name": "Sunday",
      "opens_at": "10:00:00",
      "closes_at": "20:00:00",
      "is_closed": false
    },
    {
      "id": 2,
      "day_of_week": 1,
      "day_name": "Monday",
      "opens_at": "09:00:00",
      "closes_at": "23:00:00",
      "is_closed": false
    }
    // ... days 2-6
  ],
  
  "stats": {
    "total_courts": 6,
    "total_bookings": 150,
    "active_courts": 6
  },
  
  "created_at": "2026-04-01T10:00:00Z",
  "updated_at": "2026-04-13T10:00:00Z"
}
```

### Authorization

| Action | Public | Customer | Staff/Receptionist | Admin | Owner |
|--------|--------|----------|-------------------|-------|-------|
| List | ✅ | ✅ | ✅ | ✅ | ✅ |
| Show | ✅ (basic) | ✅ (basic) | ✅ (detailed) | ✅ (detailed) | ✅ (detailed) |
| Create | ❌ | ✅ | ❌ | ❌ | ❌ |
| Update | ❌ | ❌ | ❌ | ✅ | ✅ |
| Delete | ❌ | ❌ | ❌ | ❌ | ✅ |

**Note**: Customers can create their own venue (becoming the owner).

### Business Rules

1. **One Venue Per Owner**: User can only create one venue (MVP constraint)
2. **Slug Uniqueness**: Venue slug must be unique (auto-generated from name)
3. **Operating Hours**: Must have 7 days defined (can be marked as closed)
4. **Cascade Delete Prevention**: Cannot delete venue with active bookings
5. **Settings Required**: Venue must have settings (created automatically)

### Services Needed

- `Venues::CreateService` - Create venue with nested settings/hours
- `Venues::UpdateService` - Update venue with nested settings/hours
- `Venues::DeleteService` - Soft delete with dependency checks

---

## 7. Court Types

**Status**: ⚪ Planned  
**Base Path**: `/api/v0/court_types`  
**Planned Controller**: `Api::V0::CourtTypesController`  
**Operations Needed**: 1 operation  
**Blueprint Needed**: `Api::V0::CourtTypeBlueprint`  

### Endpoints

| Method | Path | Auth | Description | Operation |
|--------|------|------|-------------|-----------|
| `GET` | `/court_types` | ❌ | List all court types (public) | `ListCourtTypesOperation` |

**Purpose**: Show available sport types (Badminton, Tennis, Basketball, etc.) when creating courts.

**MVP Constraint**: Read-only, pre-seeded data. No CRUD operations.

### Response

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Badminton",
      "slug": "badminton",
      "description": "Badminton court",
      "icon": "🏸"
    },
    {
      "id": 2,
      "name": "Tennis",
      "slug": "tennis",
      "description": "Tennis court",
      "icon": "🎾"
    },
    {
      "id": 3,
      "name": "Basketball",
      "slug": "basketball",
      "description": "Basketball court",
      "icon": "🏀"
    }
  ]
}
```

### Authorization

- Public endpoint (no authentication required)

---

## 8. Courts

**Status**: ⚪ Planned  
**Base Path**: `/api/v0/courts`  
**Planned Controller**: `Api::V0::CourtsController`  
**Operations Needed**: 5 operations  
**Blueprint Needed**: `Api::V0::CourtBlueprint`  

### Endpoints

| Method | Path | Auth | Description | Operation |
|--------|------|------|-------------|-----------|
| `GET` | `/courts` | ❌ | List courts (public, venue-scoped) | `ListCourtsOperation` |
| `GET` | `/courts/:id` | ❌ | Get court details (public) | `GetCourtOperation` |
| `POST` | `/courts` | ✅ | Create court | `CreateCourtOperation` |
| `PATCH/PUT` | `/courts/:id` | ✅ | Update court | `UpdateCourtOperation` |
| `DELETE` | `/courts/:id` | ✅ | Delete court | `DeleteCourtOperation` |

### Query Params for List (`GET /courts`)

```
?venue_id=1                 # Filter by venue (required for public access)
?court_type_id=1            # Filter by sport type
?is_active=true             # Filter by active status
?available_at=2026-04-15T10:00:00Z  # Check availability at specific time
```

### Request Body - Create Court (`POST /courts`)

```json
{
  "court": {
    "name": "Badminton Court 1",
    "court_type_id": 1,
    "description": "Premium badminton court with wooden flooring",
    "is_active": true,
    "display_order": 1
  }
}
```

**MVP Rules**:
- `venue_id` is automatically set to `current_user.venue.id`
- Court name must be unique within venue

### Request Body - Update Court (`PATCH /courts/:id`)

```json
{
  "court": {
    "name": "Badminton Court 1 (Premium)",
    "description": "Updated description",
    "is_active": true,
    "display_order": 1
  }
}
```

### Response - Court Object

**View: `:list`**
```json
{
  "id": 1,
  "venue_id": 1,
  "name": "Badminton Court 1",
  "court_type": {
    "id": 1,
    "name": "Badminton",
    "slug": "badminton",
    "icon": "🏸"
  },
  "is_active": true,
  "display_order": 1
}
```

**View: `:detailed`**
```json
{
  "id": 1,
  "venue_id": 1,
  "name": "Badminton Court 1",
  "description": "Premium badminton court with wooden flooring",
  "court_type": {
    "id": 1,
    "name": "Badminton",
    "slug": "badminton",
    "description": "Badminton court",
    "icon": "🏸"
  },
  "is_active": true,
  "display_order": 1,
  "venue": {
    "id": 1,
    "name": "Sports Arena Karachi",
    "slug": "sports-arena-karachi"
  },
  "created_at": "2026-04-01T10:00:00Z",
  "updated_at": "2026-04-13T10:00:00Z"
}
```

### Authorization

| Action | Public | Customer | Staff/Receptionist | Admin | Owner |
|--------|--------|----------|-------------------|-------|-------|
| List | ✅ (venue-scoped) | ✅ | ✅ | ✅ | ✅ |
| Show | ✅ | ✅ | ✅ | ✅ | ✅ |
| Create | ❌ | ❌ | ❌ | ✅ | ✅ |
| Update | ❌ | ❌ | ❌ | ✅ | ✅ |
| Delete | ❌ | ❌ | ❌ | ✅ | ✅ |

### Business Rules

1. **Venue Scoping**: Courts belong to specific venue
2. **Unique Names**: Court name must be unique within venue
3. **Court Type Required**: Must link to existing court type
4. **Cascade Delete Prevention**: Cannot delete court with active bookings
5. **Active Status**: Inactive courts cannot be booked

### Services Needed

- `Courts::CreateService` - Create court
- `Courts::UpdateService` - Update court
- `Courts::DeleteService` - Delete court with dependency checks

---

## 9. Pricing Rules

**Status**: ⚪ Planned  
**Base Path**: `/api/v0/pricing_rules`  
**Planned Controller**: `Api::V0::PricingRulesController`  
**Operations Needed**: 5 operations  
**Blueprint Needed**: `Api::V0::PricingRuleBlueprint`  

### Endpoints

| Method | Path | Auth | Description | Operation |
|--------|------|------|-------------|-----------|
| `GET` | `/pricing_rules` | ✅ | List pricing rules for venue | `ListPricingRulesOperation` |
| `GET` | `/pricing_rules/:id` | ✅ | Get pricing rule details | `GetPricingRuleOperation` |
| `POST` | `/pricing_rules` | ✅ | Create pricing rule | `CreatePricingRuleOperation` |
| `PATCH/PUT` | `/pricing_rules/:id` | ✅ | Update pricing rule | `UpdatePricingRuleOperation` |
| `DELETE` | `/pricing_rules/:id` | ✅ | Delete pricing rule | `DeletePricingRuleOperation` |

### Query Params for List (`GET /pricing_rules`)

```
?court_type_id=1            # Filter by court type
?is_active=true             # Filter by active status
?day_of_week=1              # Filter by day (0-6)
```

### Request Body - Create Pricing Rule (`POST /pricing_rules`)

```json
{
  "pricing_rule": {
    "court_type_id": 1,
    "name": "Weekday Evening Peak",
    "price_per_hour": 2500,
    "day_of_week": null,
    "start_time": "18:00",
    "end_time": "23:00",
    "start_date": null,
    "end_date": null,
    "priority": 2,
    "is_active": true
  }
}
```

**Rules**:
- `venue_id` is automatically set to `current_user.venue.id`
- `null` values mean "applies to all" (e.g., `day_of_week: null` = all days)
- Higher `priority` wins when multiple rules match

### Response - Pricing Rule Object

```json
{
  "id": 1,
  "venue_id": 1,
  "court_type": {
    "id": 1,
    "name": "Badminton",
    "slug": "badminton"
  },
  "name": "Weekday Evening Peak",
  "price_per_hour": 2500,
  "day_of_week": null,
  "day_name": "All days",
  "start_time": "18:00:00",
  "end_time": "23:00:00",
  "time_range": "06:00 PM - 11:00 PM",
  "start_date": null,
  "end_date": null,
  "priority": 2,
  "is_active": true,
  "created_at": "2026-04-01T10:00:00Z",
  "updated_at": "2026-04-13T10:00:00Z"
}
```

### Authorization

| Action | Owner | Admin | Receptionist | Staff | Customer |
|--------|-------|-------|--------------|-------|----------|
| List | ✅ | ✅ | ✅ (read-only) | ❌ | ❌ |
| Show | ✅ | ✅ | ✅ | ❌ | ❌ |
| Create | ✅ | ✅ | ❌ | ❌ | ❌ |
| Update | ✅ | ✅ | ❌ | ❌ | ❌ |
| Delete | ✅ | ✅ | ❌ | ❌ | ❌ |

### Business Rules

1. **Venue Scoping**: Pricing rules belong to specific venue
2. **Priority System**: Higher priority rules take precedence
3. **Time Validation**: `end_time` must be after `start_time`
4. **Date Validation**: `end_date` must be after `start_date`
5. **Price Calculation**: Used by booking system to calculate total cost

### Services Needed

- `PricingRules::CreateService` - Create pricing rule with validations
- `PricingRules::UpdateService` - Update pricing rule
- `PricingRules::DeleteService` - Delete pricing rule

---

## 10. Bookings

**Status**: ⚪ Planned  
**Base Path**: `/api/v0/bookings`  
**Planned Controller**: `Api::V0::BookingsController`  
**Operations Needed**: 10 operations  
**Blueprint Needed**: `Api::V0::BookingBlueprint`  

### Standard CRUD Endpoints

| Method | Path | Auth | Description | Operation |
|--------|------|------|-------------|-----------|
| `GET` | `/bookings` | ✅ | List bookings | `ListBookingsOperation` |
| `GET` | `/bookings/:id` | ✅ | Get booking details | `GetBookingOperation` |
| `POST` | `/bookings` | ✅ | Create booking | `CreateBookingOperation` |
| `PATCH/PUT` | `/bookings/:id` | ✅ | Update booking | `UpdateBookingOperation` |
| `DELETE` | `/bookings/:id` | ✅ | Delete booking (admin only) | `DeleteBookingOperation` |

### Special Action Endpoints

| Method | Path | Auth | Description | Operation |
|--------|------|------|-------------|-----------|
| `POST` | `/bookings/check_availability` | ✅ | Check if time slot is available | `CheckAvailabilityOperation` |
| `POST` | `/bookings/calculate_price` | ✅ | Calculate booking price | `CalculatePriceOperation` |
| `PATCH` | `/bookings/:id/cancel` | ✅ | Cancel booking | `CancelBookingOperation` |
| `PATCH` | `/bookings/:id/checkin` | ✅ | Check-in customer | `CheckinBookingOperation` |
| `PATCH` | `/bookings/:id/no_show` | ✅ | Mark as no-show | `NoShowBookingOperation` |
| `PATCH` | `/bookings/:id/complete` | ✅ | Complete booking | `CompleteBookingOperation` |
| `PATCH` | `/bookings/:id/reschedule` | ✅ | Reschedule booking | `RescheduleBookingOperation` |

**Total Booking Endpoints**: 12

### Query Params for List (`GET /bookings`)

```
?status=confirmed           # Filter by status (confirmed, completed, cancelled, no_show)
?user_id=15                 # Filter by user (admin/receptionist can see all)
?court_id=3                 # Filter by court
?start_date=2026-04-15      # Filter bookings from date
?end_date=2026-04-20        # Filter bookings until date
?date=2026-04-15            # Filter bookings on specific date
?mine=true                  # Show only current user's bookings
?page=1                     # Pagination
?per_page=20                # Items per page
```

### Request Body - Create Booking (`POST /bookings`)

```json
{
  "booking": {
    "court_id": 1,
    "start_time": "2026-04-15T18:00:00+05:00",
    "end_time": "2026-04-15T20:00:00+05:00",
    "notes": "Please keep court ready by 6 PM"
  }
}
```

**MVP Rules**:
- `user_id` is automatically set to `current_user.id` (self-booking)
- Owner/Admin/Receptionist can book on behalf of others (require `user_id` in params)
- `booking_number` is auto-generated
- `total_amount` is calculated from pricing rules
- `status` defaults to `confirmed`
- `payment_status` defaults to `pending`

### Request Body - Update Booking (`PATCH /bookings/:id`)

```json
{
  "booking": {
    "notes": "Updated notes",
    "payment_method": "cash",
    "payment_status": "paid",
    "paid_amount": 5000
  }
}
```

**Limitations**:
- Cannot change `court_id`, `start_time`, `end_time` via normal update
- Use `/reschedule` endpoint for time/court changes
- Cannot change `user_id` after creation

### Request Body - Check Availability (`POST /bookings/check_availability`)

```json
{
  "court_id": 1,
  "start_time": "2026-04-15T18:00:00+05:00",
  "end_time": "2026-04-15T20:00:00+05:00"
}
```

### Response - Check Availability

```json
{
  "success": true,
  "data": {
    "available": true,
    "court": {
      "id": 1,
      "name": "Badminton Court 1"
    },
    "requested_time": {
      "start": "2026-04-15T18:00:00+05:00",
      "end": "2026-04-15T20:00:00+05:00",
      "duration_minutes": 120
    },
    "conflicts": []
  }
}
```

**If NOT available**:
```json
{
  "success": true,
  "data": {
    "available": false,
    "court": {
      "id": 1,
      "name": "Badminton Court 1"
    },
    "requested_time": {
      "start": "2026-04-15T18:00:00+05:00",
      "end": "2026-04-15T20:00:00+05:00",
      "duration_minutes": 120
    },
    "conflicts": [
      {
        "type": "booking",
        "booking_id": 45,
        "start_time": "2026-04-15T17:00:00+05:00",
        "end_time": "2026-04-15T19:00:00+05:00"
      }
    ]
  }
}
```

### Request Body - Calculate Price (`POST /bookings/calculate_price`)

```json
{
  "court_id": 1,
  "start_time": "2026-04-15T18:00:00+05:00",
  "end_time": "2026-04-15T20:00:00+05:00"
}
```

### Response - Calculate Price

```json
{
  "success": true,
  "data": {
    "court": {
      "id": 1,
      "name": "Badminton Court 1",
      "court_type": "Badminton"
    },
    "duration_minutes": 120,
    "duration_hours": 2.0,
    "pricing_breakdown": [
      {
        "rule_name": "Weekday Evening Peak",
        "start_time": "18:00",
        "end_time": "20:00",
        "duration_hours": 2.0,
        "price_per_hour": 2500,
        "subtotal": 5000
      }
    ],
    "total_amount": 5000,
    "currency": "PKR"
  }
}
```

### Request Body - Cancel Booking (`PATCH /bookings/:id/cancel`)

```json
{
  "cancellation_reason": "Personal emergency"
}
```

### Response - Cancel Booking

```json
{
  "success": true,
  "data": {
    "id": 45,
    "booking_number": "BK-20260415-0045",
    "status": "cancelled",
    "cancelled_at": "2026-04-13T10:30:00Z",
    "cancelled_by": {
      "id": 15,
      "name": "Ahmed Khan"
    },
    "cancellation_reason": "Personal emergency"
  }
}
```

### Request Body - Check-in Booking (`PATCH /bookings/:id/checkin`)

No request body needed.

### Response - Check-in Booking

```json
{
  "success": true,
  "data": {
    "id": 45,
    "booking_number": "BK-20260415-0045",
    "status": "confirmed",
    "checked_in_at": "2026-04-15T17:55:00+05:00",
    "checked_in_by": {
      "id": 3,
      "name": "Receptionist Ali"
    }
  }
}
```

### Request Body - Reschedule Booking (`PATCH /bookings/:id/reschedule`)

```json
{
  "court_id": 2,
  "start_time": "2026-04-16T18:00:00+05:00",
  "end_time": "2026-04-16T20:00:00+05:00"
}
```

**Response**: Full updated booking object with recalculated price.

### Response - Booking Object (Detailed)

```json
{
  "id": 45,
  "booking_number": "BK-20260415-0045",
  "user": {
    "id": 15,
    "first_name": "Ahmed",
    "last_name": "Khan",
    "phone_number": "+92 300 1234567",
    "email": "ahmed@example.com"
  },
  "court": {
    "id": 1,
    "name": "Badminton Court 1",
    "court_type": "Badminton"
  },
  "venue": {
    "id": 1,
    "name": "Sports Arena Karachi"
  },
  "start_time": "2026-04-15T18:00:00+05:00",
  "end_time": "2026-04-15T20:00:00+05:00",
  "duration_minutes": 120,
  "status": "confirmed",
  "total_amount": 5000,
  "currency": "PKR",
  "payment_method": "cash",
  "payment_status": "pending",
  "paid_amount": 0,
  "notes": "Please keep court ready by 6 PM",
  "checked_in_at": null,
  "checked_in_by": null,
  "cancelled_at": null,
  "cancelled_by": null,
  "cancellation_reason": null,
  "created_by": {
    "id": 15,
    "name": "Ahmed Khan"
  },
  "created_at": "2026-04-13T10:00:00Z",
  "updated_at": "2026-04-13T10:00:00Z"
}
```

### Authorization

| Action | Owner | Admin | Receptionist | Staff | Customer |
|--------|-------|-------|--------------|-------|----------|
| List | ✅ (all) | ✅ (all) | ✅ (all) | ✅ (all) | ✅ (own only) |
| Show | ✅ (all) | ✅ (all) | ✅ (all) | ✅ (all) | ✅ (own only) |
| Create | ✅ (any user) | ✅ (any user) | ✅ (any user) | ❌ | ✅ (self only) |
| Update | ✅ | ✅ | ✅ (limited fields) | ❌ | ✅ (own, before start) |
| Delete | ✅ | ❌ | ❌ | ❌ | ❌ |
| Check Availability | ✅ | ✅ | ✅ | ✅ | ✅ |
| Calculate Price | ✅ | ✅ | ✅ | ✅ | ✅ |
| Cancel | ✅ (any) | ✅ (any) | ✅ (any) | ❌ | ✅ (own, within cancellation window) |
| Check-in | ✅ | ✅ | ✅ | ❌ | ❌ |
| No-show | ✅ | ✅ | ✅ | ❌ | ❌ |
| Complete | ✅ | ✅ | ✅ | ❌ | ❌ |
| Reschedule | ✅ (any) | ✅ (any) | ✅ (any) | ❌ | ✅ (own, within window) |

### Business Rules

1. **Double Booking Prevention**: Cannot book same court for overlapping times
2. **Slot Duration Validation**: Duration must be >= min and <= max (from venue settings)
3. **Advance Booking Limit**: Cannot book more than X days in advance (from venue settings)
4. **Past Booking Prevention**: Cannot book in the past
5. **Operating Hours**: Must be within venue operating hours
6. **Court Closure Check**: Court must not be closed for maintenance
7. **Cancellation Window**: Customer can cancel only if X hours before start time
8. **Price Calculation**: Total calculated from pricing rules based on time/duration
9. **Status Workflow**: confirmed → completed/cancelled/no_show (no going back)
10. **Audit Trail**: All changes logged in `booking_logs`

### Services Needed

- `Bookings::CreateService` - Create booking with validations and price calculation
- `Bookings::UpdateService` - Update booking
- `Bookings::DeleteService` - Hard delete (admin only)
- `Bookings::CheckAvailabilityService` - Check for conflicts
- `Bookings::CalculatePriceService` - Calculate price from pricing rules
- `Bookings::CancelService` - Cancel booking with logging
- `Bookings::CheckinService` - Check-in customer
- `Bookings::NoShowService` - Mark as no-show
- `Bookings::CompleteService` - Mark as completed
- `Bookings::RescheduleService` - Change time/court with availability check

---

## 11. Court Closures

**Status**: ⚪ Planned  
**Base Path**: `/api/v0/court_closures`  
**Planned Controller**: `Api::V0::CourtClosuresController`  
**Operations Needed**: 5 operations  
**Blueprint Needed**: `Api::V0::CourtClosureBlueprint`  

### Endpoints

| Method | Path | Auth | Description | Operation |
|--------|------|------|-------------|-----------|
| `GET` | `/court_closures` | ✅ | List court closures | `ListCourtClosuresOperation` |
| `GET` | `/court_closures/:id` | ✅ | Get closure details | `GetCourtClosureOperation` |
| `POST` | `/court_closures` | ✅ | Create closure | `CreateCourtClosureOperation` |
| `PATCH/PUT` | `/court_closures/:id` | ✅ | Update closure | `UpdateCourtClosureOperation` |
| `DELETE` | `/court_closures/:id` | ✅ | Delete closure | `DeleteCourtClosureOperation` |

### Query Params for List (`GET /court_closures`)

```
?court_id=1                 # Filter by court
?start_date=2026-04-15      # Filter closures from date
?end_date=2026-04-20        # Filter closures until date
?upcoming=true              # Show only upcoming closures
```

### Request Body - Create Court Closure (`POST /court_closures`)

```json
{
  "court_closure": {
    "court_id": 1,
    "title": "Maintenance",
    "description": "Floor polishing and net replacement",
    "start_time": "2026-04-20T09:00:00+05:00",
    "end_time": "2026-04-20T17:00:00+05:00"
  }
}
```

**MVP Rules**:
- `venue_id` is automatically set from court's venue
- Prevents bookings during closure period
- No recurring closures in MVP (future feature)

### Response - Court Closure Object

```json
{
  "id": 1,
  "court": {
    "id": 1,
    "name": "Badminton Court 1"
  },
  "venue": {
    "id": 1,
    "name": "Sports Arena Karachi"
  },
  "title": "Maintenance",
  "description": "Floor polishing and net replacement",
  "start_time": "2026-04-20T09:00:00+05:00",
  "end_time": "2026-04-20T17:00:00+05:00",
  "created_by": {
    "id": 1,
    "name": "Muhammad Ali"
  },
  "created_at": "2026-04-13T10:00:00Z",
  "updated_at": "2026-04-13T10:00:00Z"
}
```

### Authorization

| Action | Owner | Admin | Receptionist | Staff | Customer |
|--------|-------|-------|--------------|-------|----------|
| List | ✅ | ✅ | ✅ | ✅ | ❌ |
| Show | ✅ | ✅ | ✅ | ✅ | ❌ |
| Create | ✅ | ✅ | ❌ | ❌ | ❌ |
| Update | ✅ | ✅ | ❌ | ❌ | ❌ |
| Delete | ✅ | ✅ | ❌ | ❌ | ❌ |

### Business Rules

1. **Venue Scoping**: Closures belong to venue's courts
2. **Time Validation**: End time must be after start time
3. **Booking Prevention**: Cannot create bookings during closure period
4. **No Retroactive**: Cannot create closures in the past (optional validation)

### Services Needed

- `CourtClosures::CreateService` - Create closure
- `CourtClosures::UpdateService` - Update closure
- `CourtClosures::DeleteService` - Delete closure

---

## 12. Notifications

**Status**: ⚪ Planned  
**Base Path**: `/api/v0/notifications`  
**Planned Controller**: `Api::V0::NotificationsController`  
**Operations Needed**: 4 operations  
**Blueprint Needed**: `Api::V0::NotificationBlueprint`  

### Endpoints

| Method | Path | Auth | Description | Operation |
|--------|------|------|-------------|-----------|
| `GET` | `/notifications` | ✅ | List user's notifications | `ListNotificationsOperation` |
| `GET` | `/notifications/unread_count` | ✅ | Get unread count | `UnreadCountOperation` |
| `PATCH` | `/notifications/:id/read` | ✅ | Mark as read | `MarkNotificationReadOperation` |
| `PATCH` | `/notifications/mark_all_read` | ✅ | Mark all as read | `MarkAllNotificationsReadOperation` |

### Query Params for List (`GET /notifications`)

```
?type=booking_confirmation  # Filter by type
?priority=high              # Filter by priority
?read=false                 # Filter by read status (show only unread)
?page=1                     # Pagination
?per_page=20                # Items per page
```

### Response - Notification Object

```json
{
  "id": 1,
  "user_id": 15,
  "venue_id": 1,
  "notifiable_type": "Booking",
  "notifiable_id": 45,
  "type": "booking_confirmation",
  "priority": "medium",
  "title": "Booking Confirmed",
  "message": "Your booking for Badminton Court 1 on April 15, 2026 at 6:00 PM is confirmed.",
  "data": {
    "booking_id": 45,
    "booking_number": "BK-20260415-0045",
    "court_name": "Badminton Court 1",
    "start_time": "2026-04-15T18:00:00+05:00"
  },
  "read_at": null,
  "created_at": "2026-04-13T10:00:00Z"
}
```

### Response - Unread Count

```json
{
  "success": true,
  "data": {
    "unread_count": 5
  }
}
```

### Authorization

- All actions: User can only access their own notifications

### Notification Types

- `booking_confirmation` - New booking created
- `booking_cancelled` - Booking was cancelled
- `booking_rescheduled` - Booking time/court changed
- `booking_reminder` - Reminder 24h before booking (future)
- `payment_received` - Payment confirmed (future)
- `venue_announcement` - Important venue announcements

### Services Needed

- `Notifications::CreateService` - Create notification (called by other services)
- `Notifications::MarkReadService` - Mark notification as read
- `Notifications::MarkAllReadService` - Mark all user's notifications as read

---

## 13. Dashboard & Stats

**Status**: ⚪ Planned  
**Base Path**: `/api/v0/dashboard`  
**Planned Controller**: `Api::V0::DashboardController`  
**Operations Needed**: 3 operations  

### Endpoints

| Method | Path | Auth | Description | Operation |
|--------|------|------|-------------|-----------|
| `GET` | `/dashboard/overview` | ✅ | Overall venue stats | `DashboardOverviewOperation` |
| `GET` | `/dashboard/bookings_stats` | ✅ | Booking statistics | `BookingsStatsOperation` |
| `GET` | `/dashboard/revenue_stats` | ✅ | Revenue statistics | `RevenueStatsOperation` |

### Query Params for Stats

```
?start_date=2026-04-01      # Stats from date
?end_date=2026-04-30        # Stats until date
?period=month               # Grouping: day, week, month
```

### Response - Dashboard Overview (`GET /dashboard/overview`)

```json
{
  "success": true,
  "data": {
    "venue": {
      "id": 1,
      "name": "Sports Arena Karachi",
      "total_courts": 6,
      "active_courts": 6
    },
    "stats": {
      "today": {
        "total_bookings": 12,
        "confirmed": 10,
        "completed": 2,
        "cancelled": 0,
        "revenue": 30000
      },
      "this_week": {
        "total_bookings": 65,
        "confirmed": 45,
        "completed": 15,
        "cancelled": 5,
        "revenue": 162500
      },
      "this_month": {
        "total_bookings": 280,
        "confirmed": 180,
        "completed": 85,
        "cancelled": 15,
        "revenue": 700000
      }
    },
    "top_courts": [
      {
        "court_id": 1,
        "court_name": "Badminton Court 1",
        "booking_count": 85,
        "revenue": 212500
      }
    ],
    "recent_bookings": [
      // Last 5 bookings
    ]
  }
}
```

### Response - Bookings Stats (`GET /dashboard/bookings_stats`)

```json
{
  "success": true,
  "data": {
    "total_bookings": 280,
    "by_status": {
      "confirmed": 180,
      "completed": 85,
      "cancelled": 15,
      "no_show": 0
    },
    "by_court_type": [
      {
        "court_type": "Badminton",
        "count": 180,
        "percentage": 64.3
      },
      {
        "court_type": "Tennis",
        "count": 70,
        "percentage": 25.0
      }
    ],
    "by_day_of_week": [
      { "day": "Monday", "count": 45 },
      { "day": "Tuesday", "count": 42 },
      // ...
    ],
    "by_hour": [
      { "hour": 9, "count": 5 },
      { "hour": 10, "count": 8 },
      // ...
    ]
  }
}
```

### Response - Revenue Stats (`GET /dashboard/revenue_stats`)

```json
{
  "success": true,
  "data": {
    "total_revenue": 700000,
    "paid_revenue": 650000,
    "pending_revenue": 50000,
    "currency": "PKR",
    "by_payment_method": {
      "cash": 650000,
      "online": 0
    },
    "by_court_type": [
      {
        "court_type": "Badminton",
        "revenue": 450000,
        "percentage": 64.3
      }
    ],
    "timeline": [
      {
        "date": "2026-04-01",
        "revenue": 25000,
        "bookings_count": 10
      },
      {
        "date": "2026-04-02",
        "revenue": 22000,
        "bookings_count": 9
      }
      // ...
    ]
  }
}
```

### Authorization

- Owner, Admin: Full access to all dashboard stats
- Others: Cannot access

### Services Needed

- `Dashboard::OverviewService` - Calculate overall venue statistics
- `Dashboard::BookingsStatsService` - Calculate booking statistics
- `Dashboard::RevenueStatsService` - Calculate revenue statistics

---

## Authorization Matrix

### Resource-Level Permissions

| Resource | Owner | Admin | Receptionist | Staff | Customer |
|----------|-------|-------|--------------|-------|----------|
| **Users** | Full | Full | Read | Read | Self only |
| **Roles** | Full | Read | Read | - | - |
| **Permissions** | Read | Read | - | - | - |
| **User Roles** | Full | Full | - | - | - |
| **Venues** | Full | Update | Read | Read | Create own |
| **Court Types** | Read | Read | Read | Read | Read (public) |
| **Courts** | Full | Full | Read | Read | Read (public) |
| **Pricing Rules** | Full | Full | Read | - | - |
| **Bookings** | Full | Full | Full | Read | Self only |
| **Court Closures** | Full | Full | Read | Read | - |
| **Notifications** | Self | Self | Self | Self | Self |
| **Dashboard** | Full | Full | - | - | - |

---

## Search & Filter Capabilities

### Venues (`GET /api/v0/venues`)
- Search by: name, description
- Filter by: city, state, is_active
- Sort by: name, created_at

### Users (`GET /api/v0/users`)
- Search by: name (first_name, last_name), email, phone_number
- Filter by: role, is_active
- Sort by: name, created_at

### Courts (`GET /api/v0/courts`)
- Filter by: venue_id, court_type_id, is_active
- Sort by: display_order, name

### Pricing Rules (`GET /api/v0/pricing_rules`)
- Filter by: court_type_id, day_of_week, is_active
- Sort by: priority, created_at

### Bookings (`GET /api/v0/bookings`)
- Search by: booking_number, user name, court name
- Filter by: status, user_id, court_id, date range
- Sort by: start_time, created_at, status

### Court Closures (`GET /api/v0/court_closures`)
- Filter by: court_id, date range, upcoming
- Sort by: start_time, created_at

### Notifications (`GET /api/v0/notifications`)
- Filter by: type, priority, read status
- Sort by: created_at (desc)

---

## Implementation Checklist

### Phase A: Foundation (Week 1)

#### Users Resource
- [ ] Create `Api::V0::UsersController`
- [ ] Create 7 operations:
  - [ ] `ListUsersOperation` with filters (role, is_active, search)
  - [ ] `GetUserOperation`
  - [ ] `GetCurrentUserOperation`
  - [ ] `CreateUserOperation` with role assignment
  - [ ] `UpdateUserOperation`
  - [ ] `ActivateUserOperation`
  - [ ] `DeactivateUserOperation`
- [ ] Create services:
  - [ ] `Users::CreateService`
  - [ ] `Users::UpdateService`
  - [ ] `Users::ActivateService`
  - [ ] `Users::DeactivateService`
- [ ] Update `Api::V0::UserBlueprint` with `:list` and `:detailed` views
- [ ] Create `UserPolicy` with all actions
- [ ] Add routes to `config/routes/api_v0.rb`
- [ ] Write request specs for all endpoints
- [ ] Write service specs
- [ ] Test authorization for all roles

#### Permissions Resource
- [ ] Create `Api::V0::PermissionsController`
- [ ] Create `ListPermissionsOperation` with filters
- [ ] Update `Api::V0::PermissionBlueprint`
- [ ] Create `PermissionPolicy`
- [ ] Add routes
- [ ] Write request specs

#### User Roles Resource
- [ ] Create `Api::V0::UserRolesController`
- [ ] Create operations:
  - [ ] `AssignRoleOperation`
  - [ ] `RemoveRoleOperation`
- [ ] Create services:
  - [ ] `UserRoles::AssignService`
  - [ ] `UserRoles::RemoveService`
- [ ] Create `Api::V0::UserRoleBlueprint`
- [ ] Create `UserRolePolicy`
- [ ] Add routes
- [ ] Write request specs

### Phase B: Venue Setup (Week 1-2)

#### Venues Resource
- [ ] Create `Api::V0::VenuesController`
- [ ] Create 5 operations:
  - [ ] `ListVenuesOperation` (public) with search/filters
  - [ ] `GetVenueOperation` (public)
  - [ ] `CreateVenueOperation` with nested attributes
  - [ ] `UpdateVenueOperation` with nested attributes
  - [ ] `DeleteVenueOperation`
- [ ] Create services:
  - [ ] `Venues::CreateService`
  - [ ] `Venues::UpdateService`
  - [ ] `Venues::DeleteService`
- [ ] Create `Api::V0::VenueBlueprint` with views (`:list`, `:detailed`)
- [ ] Create `VenuePolicy`
- [ ] Add routes
- [ ] Write request specs
- [ ] Test nested attributes (settings, operating hours)

#### Court Types Resource
- [ ] Create `Api::V0::CourtTypesController`
- [ ] Create `ListCourtTypesOperation` (public)
- [ ] Create `Api::V0::CourtTypeBlueprint`
- [ ] Add routes (read-only)
- [ ] Write request specs

#### Courts Resource
- [ ] Create `Api::V0::CourtsController`
- [ ] Create 5 operations:
  - [ ] `ListCourtsOperation` with filters
  - [ ] `GetCourtOperation`
  - [ ] `CreateCourtOperation`
  - [ ] `UpdateCourtOperation`
  - [ ] `DeleteCourtOperation`
- [ ] Create services:
  - [ ] `Courts::CreateService`
  - [ ] `Courts::UpdateService`
  - [ ] `Courts::DeleteService`
- [ ] Create `Api::V0::CourtBlueprint`
- [ ] Create `CourtPolicy`
- [ ] Add routes
- [ ] Write request specs

#### Pricing Rules Resource
- [ ] Create `Api::V0::PricingRulesController`
- [ ] Create 5 operations:
  - [ ] `ListPricingRulesOperation`
  - [ ] `GetPricingRuleOperation`
  - [ ] `CreatePricingRuleOperation`
  - [ ] `UpdatePricingRuleOperation`
  - [ ] `DeletePricingRuleOperation`
- [ ] Create services:
  - [ ] `PricingRules::CreateService`
  - [ ] `PricingRules::UpdateService`
  - [ ] `PricingRules::DeleteService`
- [ ] Create `Api::V0::PricingRuleBlueprint`
- [ ] Create `PricingRulePolicy`
- [ ] Add routes
- [ ] Write request specs

### Phase C: Core Booking (Week 2-3)

#### Bookings Resource
- [ ] Create `Api::V0::BookingsController`
- [ ] Create standard CRUD operations:
  - [ ] `ListBookingsOperation` with extensive filters
  - [ ] `GetBookingOperation`
  - [ ] `CreateBookingOperation`
  - [ ] `UpdateBookingOperation`
  - [ ] `DeleteBookingOperation`
- [ ] Create special operations:
  - [ ] `CheckAvailabilityOperation`
  - [ ] `CalculatePriceOperation`
  - [ ] `CancelBookingOperation`
  - [ ] `CheckinBookingOperation`
  - [ ] `NoShowBookingOperation`
  - [ ] `CompleteBookingOperation`
  - [ ] `RescheduleBookingOperation`
- [ ] Create services:
  - [ ] `Bookings::CreateService` (with availability + price calculation)
  - [ ] `Bookings::UpdateService`
  - [ ] `Bookings::DeleteService`
  - [ ] `Bookings::CheckAvailabilityService`
  - [ ] `Bookings::CalculatePriceService`
  - [ ] `Bookings::CancelService`
  - [ ] `Bookings::CheckinService`
  - [ ] `Bookings::NoShowService`
  - [ ] `Bookings::CompleteService`
  - [ ] `Bookings::RescheduleService`
  - [ ] `Bookings::GenerateBookingNumberService`
  - [ ] `Bookings::LogChangeService` (for booking_logs audit trail)
- [ ] Create `Api::V0::BookingBlueprint` with views (`:list`, `:detailed`)
- [ ] Create `BookingPolicy` with complex authorization logic
- [ ] Add routes (12 endpoints total)
- [ ] Write comprehensive request specs
- [ ] Test all business rules (double booking, time slots, cancellation window, etc.)
- [ ] Test booking logs audit trail

### Phase D: Operations Support (Week 3-4)

#### Court Closures Resource
- [ ] Create `Api::V0::CourtClosuresController`
- [ ] Create 5 operations:
  - [ ] `ListCourtClosuresOperation`
  - [ ] `GetCourtClosureOperation`
  - [ ] `CreateCourtClosureOperation`
  - [ ] `UpdateCourtClosureOperation`
  - [ ] `DeleteCourtClosureOperation`
- [ ] Create services:
  - [ ] `CourtClosures::CreateService`
  - [ ] `CourtClosures::UpdateService`
  - [ ] `CourtClosures::DeleteService`
- [ ] Create `Api::V0::CourtClosureBlueprint`
- [ ] Create `CourtClosurePolicy`
- [ ] Add routes
- [ ] Write request specs
- [ ] Test interaction with booking availability

#### Notifications Resource
- [ ] Create `Api::V0::NotificationsController`
- [ ] Create 4 operations:
  - [ ] `ListNotificationsOperation`
  - [ ] `UnreadCountOperation`
  - [ ] `MarkNotificationReadOperation`
  - [ ] `MarkAllNotificationsReadOperation`
- [ ] Create services:
  - [ ] `Notifications::CreateService` (called by booking services)
  - [ ] `Notifications::MarkReadService`
  - [ ] `Notifications::MarkAllReadService`
- [ ] Create `Api::V0::NotificationBlueprint`
- [ ] Create `NotificationPolicy`
- [ ] Add routes
- [ ] Write request specs
- [ ] Integrate with booking creation/cancellation

#### Dashboard Resource
- [ ] Create `Api::V0::DashboardController`
- [ ] Create 3 operations:
  - [ ] `DashboardOverviewOperation`
  - [ ] `BookingsStatsOperation`
  - [ ] `RevenueStatsOperation`
- [ ] Create services:
  - [ ] `Dashboard::OverviewService`
  - [ ] `Dashboard::BookingsStatsService`
  - [ ] `Dashboard::RevenueStatsService`
- [ ] Create dashboard blueprints/serializers
- [ ] Create `DashboardPolicy`
- [ ] Add routes
- [ ] Write request specs
- [ ] Test performance with large datasets

---

## API Response Standards

### Success Response Structure

```json
{
  "success": true,
  "data": {
    // Single resource or array of resources
  },
  "meta": {
    // Optional metadata (pagination, counts, etc.)
  }
}
```

### Pagination Format (Using Pagy gem)

```json
{
  "success": true,
  "data": [
    // Array of resources
  ],
  "meta": {
    "pagination": {
      "current_page": 1,
      "total_pages": 10,
      "total_count": 195,
      "per_page": 20,
      "next_page": 2,
      "prev_page": null
    }
  }
}
```

### Error Response Structure

```json
{
  "success": false,
  "errors": {
    "email": ["has already been taken"],
    "phone_number": ["is invalid"]
  }
}
```

Or for single error:

```json
{
  "success": false,
  "error": "Resource not found"
}
```

### HTTP Status Codes

| Status Code | Usage |
|-------------|-------|
| `200 OK` | Successful GET, PATCH, PUT |
| `201 Created` | Successful POST (resource created) |
| `204 No Content` | Successful DELETE |
| `400 Bad Request` | Invalid request format |
| `401 Unauthorized` | Not authenticated (missing/invalid token) |
| `403 Forbidden` | Not authorized (no permission) |
| `404 Not Found` | Resource not found |
| `422 Unprocessable Entity` | Validation errors |
| `500 Internal Server Error` | Server error |

---

## Testing Requirements

### Request Specs

Each endpoint must have request specs covering:

1. **Happy Path**: Successful request with valid data
2. **Validation Errors**: Invalid data returns 422 with errors
3. **Authorization**: Unauthorized access returns 403
4. **Not Found**: Invalid ID returns 404
5. **Edge Cases**: Boundary conditions, empty lists, etc.

### Service Specs

Each service must have unit specs covering:

1. **Success Cases**: Service returns success with correct data
2. **Failure Cases**: Service returns failure with errors
3. **Business Logic**: All business rules validated
4. **Side Effects**: Associated records created/updated correctly

### Integration Specs

Test critical workflows end-to-end:

1. **Booking Flow**: Check availability → Calculate price → Create booking
2. **User Management**: Create user → Assign role → Update profile
3. **Venue Setup**: Create venue → Add courts → Set pricing rules

### Policy Specs

Each policy must have specs for all actions and roles.

---

## API Documentation

### Tools to Use

1. **Swagger/OpenAPI**: Generate interactive API documentation
2. **RSwag**: Generate Swagger docs from request specs
3. **Postman Collection**: Export API collection for manual testing

### Documentation Includes

- Endpoint URL and HTTP method
- Request parameters (query, path, body)
- Request body schema (JSON example)
- Response schema (JSON example)
- Authentication requirements
- Authorization rules
- Error responses
- Example curl commands

---

## Performance Considerations

### Optimization Strategies

1. **Eager Loading**: Use `includes` to prevent N+1 queries
2. **Database Indexes**: All foreign keys and frequently queried fields indexed
3. **Pagination**: Always paginate list endpoints (default: 20 per page)
4. **Caching**: Cache court types, permissions (rarely change)
5. **Background Jobs**: Send notifications via Sidekiq (future)
6. **Query Optimization**: Use scopes, avoid complex joins in controllers

### Monitoring

- Track slow queries with Bullet gem
- Monitor API response times
- Log all errors to Sentry/Rollbar

---

## Security Considerations

1. **Authentication**: JWT tokens with expiration (15 min access, 7 days refresh)
2. **Authorization**: Pundit policies for all actions
3. **Venue Scoping**: Users can only access data in their venue
4. **Password Security**: bcrypt with strong hashing
5. **SQL Injection**: Use ActiveRecord queries (no raw SQL)
6. **Mass Assignment**: Use strong params in operations (contracts)
7. **Rate Limiting**: Add Rack::Attack for API rate limiting
8. **CORS**: Configure allowed origins for frontend
9. **Audit Logging**: Track all booking changes in booking_logs

---

## Next Steps

1. **Review this plan** with team
2. **Prioritize phases** based on business needs
3. **Start with Phase A** (Users, Permissions, User Roles)
4. **Implement one resource at a time** following the checklist
5. **Write tests first** (TDD approach recommended)
6. **Review code** before moving to next resource
7. **Deploy to staging** after each phase
8. **Gather feedback** from stakeholders

---

**Document Version**: 1.0  
**Last Updated**: 2026-04-13  
**Status**: Ready for Implementation

---

**Total Endpoints Planned**: 59  
**Total Operations**: 53  
**Total Services**: ~35  
**Total Blueprints**: 11  
**Total Policies**: 11  

**Estimated Development Time**: 3-4 weeks (1 developer full-time)

---

*This is a living document. Update as implementation progresses and requirements change.*
