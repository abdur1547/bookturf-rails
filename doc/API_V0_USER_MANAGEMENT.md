# API v0: User Management Endpoints

**Version**: 1.0  
**Base URL**: `/api/v0`  
**Authentication**: Required (JWT via Bearer token or cookies)  
**Authorization**: Pundit policies + venue scoping  
**Pagination**: Pagy gem  
**Last Updated**: 2026-04-07

---

## Table of Contents

1. [Overview](#overview)
2. [Authentication & Authorization](#authentication--authorization)
3. [Common Response Formats](#common-response-formats)
4. [Users Endpoints](#users-endpoints)
5. [Roles Endpoints](#roles-endpoints)
6. [Permissions Endpoints](#permissions-endpoints)
7. [User Roles Endpoints](#user-roles-endpoints)
8. [Role Permissions Endpoints](#role-permissions-endpoints)
9. [Batch Operations](#batch-operations)
10. [Services Architecture](#services-architecture)
11. [Implementation Checklist](#implementation-checklist)

---

## Overview

This document describes the REST API endpoints for managing users, roles, and permissions in the Bookturf application. These endpoints are designed for:

- **Owner & Admin**: Full user management within their venue
- **Frontend Integration**: Angular app will consume these JSON APIs
- **No HTML Views**: Pure JSON responses
- **Venue Scoping**: Users are scoped to specific venues
- **Audit Logging**: All role/permission changes are logged

### Key Principles

1. **Business Logic in Services**: Reusable logic across API versions
2. **Operations for Orchestration**: Validate params and coordinate services
3. **Pundit for Authorization**: Policy-based access control
4. **Blueprinter for Serialization**: Consistent JSON responses
5. **Venue Isolation**: Users can only access/manage users in their venue

---

## Authentication & Authorization

### Authentication

All endpoints require authentication via JWT token:

```http
Authorization: Bearer <access_token>
```

Or via HTTP-only cookies (automatically set during signin).

### Authorization Levels

| Role | Capabilities |
|------|-------------|
| **Owner** | Full access to all users, roles, permissions in their venue |
| **Admin** | Can manage users and assign existing roles (cannot create/delete custom roles) |
| **Receptionist** | Read-only access to user list |
| **Staff** | Read-only access to user list |
| **Customer** | Can only view/update their own profile |

### Venue Scoping

- All endpoints are **venue-scoped** by default
- Users can only see/manage other users in the same venue
- `current_user.venue` is used to scope all queries
- Global admins bypass venue scoping (for development/support)

---

## Common Response Formats

### Success Response

```json
{
  "success": true,
  "data": {
    // Response payload
  },
  "meta": {
    // Optional metadata (pagination, etc.)
  }
}
```

### Error Response

```json
{
  "success": false,
  "errors": [
    "Error message 1",
    "Error message 2"
  ]
}
```

### Validation Error Response

```json
{
  "success": false,
  "errors": {
    "email": ["has already been taken"],
    "password": ["is too short (minimum is 8 characters)"]
  }
}
```

### Pagination Metadata

```json
{
  "success": true,
  "data": [...],
  "meta": {
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_count": 47,
      "per_page": 10,
      "next_page": 2,
      "prev_page": null
    }
  }
}
```

---

## Users Endpoints

### 1. List Users

**GET** `/api/v0/users`

List all users in the current user's venue.

#### Authorization
- Owner/Admin: All users in venue
- Receptionist/Staff: Basic user info only
- Customer: Forbidden

#### Query Parameters

| Parameter | Type | Required | Description | Example |
|-----------|------|----------|-------------|---------|
| `page` | Integer | No | Page number (default: 1) | `?page=2` |
| `per_page` | Integer | No | Items per page (default: 10, max: 100) | `?per_page=25` |
| `search` | String | No | Search by name, email, or phone | `?search=john` |
| `role` | String | No | Filter by role slug | `?role=customer` |
| `status` | String | No | Filter by status: `active`, `inactive` | `?status=active` |
| `sort` | String | No | Sort field: `name`, `email`, `created_at` | `?sort=name` |
| `order` | String | No | Sort order: `asc`, `desc` (default: asc) | `?order=desc` |

#### Request Example

```http
GET /api/v0/users?page=1&per_page=10&search=john&role=customer&status=active
Authorization: Bearer <access_token>
```

#### Response (200 OK)

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "email": "john.doe@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "phone_number": "+92 333 1234567",
      "is_active": true,
      "roles": [
        {
          "id": 5,
          "name": "Customer",
          "slug": "customer"
        }
      ],
      "created_at": "2026-04-01T10:30:00Z",
      "updated_at": "2026-04-05T14:20:00Z"
    }
  ],
  "meta": {
    "pagination": {
      "current_page": 1,
      "total_pages": 3,
      "total_count": 28,
      "per_page": 10,
      "next_page": 2,
      "prev_page": null
    }
  }
}
```

#### Implementation Notes

**Controller**: `Api::V0::UsersController#index`  
**Operation**: `Api::V0::Users::ListUsersOperation`  
**Service**: `Users::FilterService`, `Users::SearchService`  
**Policy**: `UserPolicy#index?`  
**Blueprint**: `Api::V0::UserBlueprint` (list view)

---

### 2. Get User Details

**GET** `/api/v0/users/:id`

Get detailed information about a specific user.

#### Authorization
- Owner/Admin: Any user in venue
- User: Only their own profile
- Others: Forbidden

#### Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | Integer | Yes | User ID |

#### Request Example

```http
GET /api/v0/users/1
Authorization: Bearer <access_token>
```

#### Response (200 OK)

```json
{
  "success": true,
  "data": {
    "id": 1,
    "email": "john.doe@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "phone_number": "+92 333 1234567",
    "emergency_contact_name": "Jane Doe",
    "emergency_contact_phone": "+92 333 7654321",
    "is_active": true,
    "is_global_admin": false,
    "roles": [
      {
        "id": 5,
        "name": "Customer",
        "slug": "customer",
        "is_custom": false
      }
    ],
    "permissions": [
      "create:bookings",
      "read:bookings",
      "update:bookings",
      "read:courts"
    ],
    "created_at": "2026-04-01T10:30:00Z",
    "updated_at": "2026-04-05T14:20:00Z",
    "last_sign_in_at": "2026-04-07T08:15:00Z"
  }
}
```

#### Errors

- **404 Not Found**: User doesn't exist or not in current venue
- **403 Forbidden**: Insufficient permissions

#### Implementation Notes

**Controller**: `Api::V0::UsersController#show`  
**Operation**: `Api::V0::Users::GetUserOperation`  
**Policy**: `UserPolicy#show?`  
**Blueprint**: `Api::V0::UserBlueprint` (detailed view)

---

### 3. Create User

**POST** `/api/v0/users`

Create a new user in the current venue.

#### Authorization
- Owner/Admin: Can create users
- Others: Forbidden

#### Request Body

```json
{
  "user": {
    "email": "newuser@example.com",
    "first_name": "New",
    "last_name": "User",
    "password": "SecurePass123!",
    "password_confirmation": "SecurePass123!",
    "phone_number": "+92 333 9876543",
    "emergency_contact_name": "Emergency Contact",
    "emergency_contact_phone": "+92 333 1111111",
    "is_active": true,
    "role_ids": [5]
  }
}
```

#### Request Example

```http
POST /api/v0/users
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "user": {
    "email": "newuser@example.com",
    "first_name": "New",
    "last_name": "User",
    "password": "SecurePass123!",
    "password_confirmation": "SecurePass123!",
    "phone_number": "+92 333 9876543",
    "role_ids": [5]
  }
}
```

#### Response (201 Created)

```json
{
  "success": true,
  "data": {
    "id": 15,
    "email": "newuser@example.com",
    "first_name": "New",
    "last_name": "User",
    "phone_number": "+92 333 9876543",
    "is_active": true,
    "roles": [
      {
        "id": 5,
        "name": "Customer",
        "slug": "customer"
      }
    ],
    "created_at": "2026-04-07T10:30:00Z"
  }
}
```

#### Validation Rules

| Field | Rules |
|-------|-------|
| `email` | Required, unique, valid format |
| `first_name` | Required, min 2 chars |
| `last_name` | Required, min 2 chars |
| `password` | Required, min 8 chars, complexity rules |
| `password_confirmation` | Must match password |
| `phone_number` | Optional, valid format |
| `role_ids` | Optional, array of valid role IDs |

#### Errors

- **422 Unprocessable Entity**: Validation errors
- **403 Forbidden**: Insufficient permissions

#### Implementation Notes

**Controller**: `Api::V0::UsersController#create`  
**Operation**: `Api::V0::Users::CreateUserOperation`  
**Service**: `Users::CreateService`, `Users::AssignRolesService`  
**Policy**: `UserPolicy#create?`  
**Blueprint**: `Api::V0::UserBlueprint`

---

### 4. Update User

**PATCH/PUT** `/api/v0/users/:id`

Update an existing user's information.

#### Authorization
- Owner/Admin: Can update any user in venue
- User: Can update their own profile (limited fields)
- Others: Forbidden

#### Updateable Fields

| Field | Owner/Admin | Self |
|-------|-------------|------|
| `first_name` | ✅ | ✅ |
| `last_name` | ✅ | ✅ |
| `phone_number` | ✅ | ✅ |
| `emergency_contact_name` | ✅ | ✅ |
| `emergency_contact_phone` | ✅ | ✅ |
| `email` | ✅ | ✅ (requires verification) |
| `is_active` | ✅ | ❌ |
| `role_ids` | ✅ | ❌ |

#### Request Body

```json
{
  "user": {
    "first_name": "Updated",
    "last_name": "Name",
    "phone_number": "+92 333 5555555",
    "emergency_contact_name": "New Emergency",
    "emergency_contact_phone": "+92 333 6666666",
    "is_active": true,
    "role_ids": [5, 6]
  }
}
```

#### Response (200 OK)

```json
{
  "success": true,
  "data": {
    "id": 1,
    "email": "john.doe@example.com",
    "first_name": "Updated",
    "last_name": "Name",
    "phone_number": "+92 333 5555555",
    "emergency_contact_name": "New Emergency",
    "emergency_contact_phone": "+92 333 6666666",
    "is_active": true,
    "roles": [
      {
        "id": 5,
        "name": "Customer",
        "slug": "customer"
      },
      {
        "id": 6,
        "name": "Staff",
        "slug": "staff"
      }
    ],
    "updated_at": "2026-04-07T11:45:00Z"
  }
}
```

#### Errors

- **422 Unprocessable Entity**: Validation errors
- **403 Forbidden**: Insufficient permissions or trying to update restricted fields
- **404 Not Found**: User doesn't exist

#### Implementation Notes

**Controller**: `Api::V0::UsersController#update`  
**Operation**: `Api::V0::Users::UpdateUserOperation`  
**Service**: `Users::UpdateService`, `Users::SyncRolesService`  
**Policy**: `UserPolicy#update?`  
**Blueprint**: `Api::V0::UserBlueprint`

---

### 5. Delete User

**DELETE** `/api/v0/users/:id`

Permanently delete a user from the database.

#### Authorization
- Owner/Admin: Can delete any user in venue (except themselves)
- Others: Forbidden

#### Request Example

```http
DELETE /api/v0/users/15
Authorization: Bearer <access_token>
```

#### Response (200 OK)

```json
{
  "success": true,
  "data": {
    "message": "User deleted successfully"
  }
}
```

#### Business Rules

1. Cannot delete yourself
2. Cannot delete the venue owner
3. Permanently removes user from the database
4. All associated user_roles are cascade deleted
5. Cannot delete if user has active bookings

#### Errors

- **403 Forbidden**: Cannot delete yourself or venue owner
- **404 Not Found**: User doesn't exist
- **422 Unprocessable Entity**: User has active bookings

#### Implementation Notes

**Controller**: `Api::V0::UsersController#destroy`  
**Operation**: `Api::V0::Users::DeleteUserOperation`  
**Service**: `Users::DeleteService`  
**Policy**: `UserPolicy#destroy?`

---

### 6. Change Password

**PATCH** `/api/v0/users/:id/change_password`

Change a user's password.

#### Authorization
- User: Can change their own password
- Owner/Admin: Can reset any user's password in venue

#### Request Body

```json
{
  "current_password": "OldPass123!",
  "password": "NewPass456!",
  "password_confirmation": "NewPass456!"
}
```

**Note**: `current_password` is only required when users change their own password.

#### Response (200 OK)

```json
{
  "success": true,
  "data": {
    "message": "Password changed successfully"
  }
}
```

#### Errors

- **422 Unprocessable Entity**: Current password incorrect or validation errors
- **403 Forbidden**: Insufficient permissions

#### Implementation Notes

**Controller**: `Api::V0::UsersController#change_password`  
**Operation**: `Api::V0::Users::ChangePasswordOperation`  
**Service**: `Users::ChangePasswordService`  
**Policy**: `UserPolicy#change_password?`

---

### 7. Activate/Deactivate User

**PATCH** `/api/v0/users/:id/toggle_status`

Toggle a user's active status.

#### Authorization
- Owner/Admin: Can toggle any user in venue
- Others: Forbidden

#### Request Body

```json
{
  "is_active": true
}
```

#### Response (200 OK)

```json
{
  "success": true,
  "data": {
    "id": 15,
    "is_active": true,
    "updated_at": "2026-04-07T12:00:00Z"
  }
}
```

#### Implementation Notes

**Controller**: `Api::V0::UsersController#toggle_status`  
**Operation**: `Api::V0::Users::ToggleStatusOperation`  
**Service**: `Users::UpdateService`  
**Policy**: `UserPolicy#toggle_status?`

---

## Roles Endpoints

### 8. List Roles

**GET** `/api/v0/roles`

List all available roles (system + custom roles for the venue).

#### Authorization
- Owner/Admin/Receptionist: Can view all roles
- Others: Forbidden

#### Query Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `type` | String | Filter by type: `system`, `custom`, `all` (default: all) |
| `sort` | String | Sort by: `name`, `created_at` |

#### Response (200 OK)

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Owner",
      "slug": "owner",
      "description": "Venue owner with full control",
      "is_custom": false,
      "permissions_count": 45,
      "users_count": 1,
      "created_at": "2026-04-01T00:00:00Z"
    },
    {
      "id": 6,
      "name": "Court Manager",
      "slug": "court_manager",
      "description": "Manages courts and schedules",
      "is_custom": true,
      "permissions_count": 12,
      "users_count": 3,
      "created_at": "2026-04-05T10:00:00Z"
    }
  ]
}
```

#### Implementation Notes

**Controller**: `Api::V0::RolesController#index`  
**Operation**: `Api::V0::Roles::ListRolesOperation`  
**Policy**: `RolePolicy#index?`  
**Blueprint**: `Api::V0::RoleBlueprint` (list view)

---

### 9. Get Role Details

**GET** `/api/v0/roles/:id`

Get detailed information about a specific role including its permissions.

#### Authorization
- Owner/Admin: Can view any role
- Others: Forbidden

#### Response (200 OK)

```json
{
  "success": true,
  "data": {
    "id": 6,
    "name": "Court Manager",
    "slug": "court_manager",
    "description": "Manages courts and schedules",
    "is_custom": true,
    "permissions": [
      {
        "id": 10,
        "name": "create:courts",
        "resource": "courts",
        "action": "create",
        "description": "Can create courts"
      },
      {
        "id": 11,
        "name": "read:courts",
        "resource": "courts",
        "action": "read",
        "description": "Can read courts"
      }
    ],
    "users": [
      {
        "id": 5,
        "name": "John Doe",
        "email": "john@example.com"
      }
    ],
    "created_at": "2026-04-05T10:00:00Z",
    "updated_at": "2026-04-06T14:30:00Z"
  }
}
```

#### Implementation Notes

**Controller**: `Api::V0::RolesController#show`  
**Operation**: `Api::V0::Roles::GetRoleOperation`  
**Policy**: `RolePolicy#show?`  
**Blueprint**: `Api::V0::RoleBlueprint` (detailed view)

---

### 10. Create Custom Role

**POST** `/api/v0/roles`

Create a new custom role for the venue.

#### Authorization
- Owner: Can create custom roles
- Others: Forbidden

#### Request Body

```json
{
  "role": {
    "name": "Court Manager",
    "description": "Manages courts and schedules",
    "permission_ids": [10, 11, 12, 13]
  }
}
```

#### Response (201 Created)

```json
{
  "success": true,
  "data": {
    "id": 6,
    "name": "Court Manager",
    "slug": "court_manager",
    "description": "Manages courts and schedules",
    "is_custom": true,
    "permissions": [
      {
        "id": 10,
        "name": "create:courts",
        "resource": "courts",
        "action": "create"
      }
    ],
    "created_at": "2026-04-07T12:00:00Z"
  }
}
```

#### Validation Rules

| Field | Rules |
|-------|-------|
| `name` | Required, unique, min 2 chars |
| `description` | Optional |
| `permission_ids` | Optional, array of valid permission IDs |

#### Errors

- **422 Unprocessable Entity**: Validation errors or duplicate role name
- **403 Forbidden**: Insufficient permissions

#### Implementation Notes

**Controller**: `Api::V0::RolesController#create`  
**Operation**: `Api::V0::Roles::CreateRoleOperation`  
**Service**: `Roles::CreateService`, `Roles::AssignPermissionsService`  
**Policy**: `RolePolicy#create?`  
**Blueprint**: `Api::V0::RoleBlueprint`

---

### 11. Update Custom Role

**PATCH/PUT** `/api/v0/roles/:id`

Update a custom role's name, description, or permissions.

#### Authorization
- Owner: Can update custom roles
- Others: Forbidden

#### Request Body

```json
{
  "role": {
    "name": "Updated Court Manager",
    "description": "Updated description",
    "permission_ids": [10, 11, 12, 13, 14]
  }
}
```

#### Response (200 OK)

```json
{
  "success": true,
  "data": {
    "id": 6,
    "name": "Updated Court Manager",
    "slug": "updated_court_manager",
    "description": "Updated description",
    "is_custom": true,
    "permissions_count": 5,
    "updated_at": "2026-04-07T13:00:00Z"
  }
}
```

#### Business Rules

1. Can only update custom roles (system roles are read-only)
2. Cannot update role if it would remove critical permissions from users
3. Slug is regenerated based on new name

#### Errors

- **403 Forbidden**: Cannot update system roles
- **422 Unprocessable Entity**: Validation errors

#### Implementation Notes

**Controller**: `Api::V0::RolesController#update`  
**Operation**: `Api::V0::Roles::UpdateRoleOperation`  
**Service**: `Roles::UpdateService`, `Roles::SyncPermissionsService`  
**Policy**: `RolePolicy#update?`  
**Blueprint**: `Api::V0::RoleBlueprint`

---

### 12. Delete Custom Role

**DELETE** `/api/v0/roles/:id`

Delete a custom role.

#### Authorization
- Owner: Can delete custom roles
- Others: Forbidden

#### Response (200 OK)

```json
{
  "success": true,
  "data": {
    "message": "Role deleted successfully"
  }
}
```

#### Business Rules

1. Can only delete custom roles (system roles cannot be deleted)
2. Cannot delete role if users are currently assigned to it
3. Must reassign users first before deleting

#### Errors

- **403 Forbidden**: Cannot delete system roles
- **422 Unprocessable Entity**: Role has assigned users

#### Implementation Notes

**Controller**: `Api::V0::RolesController#destroy`  
**Operation**: `Api::V0::Roles::DeleteRoleOperation`  
**Service**: `Roles::DeleteService`  
**Policy**: `RolePolicy#destroy?`

---

## Permissions Endpoints

### 13. List Permissions

**GET** `/api/v0/permissions`

List all available permissions in the system.

#### Authorization
- Owner/Admin: Can view all permissions
- Others: Forbidden

#### Query Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `resource` | String | Filter by resource (e.g., `bookings`, `courts`) |
| `action` | String | Filter by action (e.g., `create`, `read`, `manage`) |
| `sort` | String | Sort by: `name`, `resource`, `action` |

#### Response (200 OK)

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "create:bookings",
      "resource": "bookings",
      "action": "create",
      "description": "Can create bookings"
    },
    {
      "id": 2,
      "name": "read:bookings",
      "resource": "bookings",
      "action": "read",
      "description": "Can read bookings"
    }
  ],
  "meta": {
    "grouped_by_resource": {
      "bookings": ["create:bookings", "read:bookings", "update:bookings"],
      "courts": ["create:courts", "read:courts"]
    }
  }
}
```

#### Implementation Notes

**Controller**: `Api::V0::PermissionsController#index`  
**Operation**: `Api::V0::Permissions::ListPermissionsOperation`  
**Service**: `Permissions::FilterService`  
**Policy**: `PermissionPolicy#index?`  
**Blueprint**: `Api::V0::PermissionBlueprint`

---

### 14. Get Permission Details

**GET** `/api/v0/permissions/:id`

Get details about a specific permission including which roles have it.

#### Authorization
- Owner/Admin: Can view permission details
- Others: Forbidden

#### Response (200 OK)

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "create:bookings",
    "resource": "bookings",
    "action": "create",
    "description": "Can create bookings",
    "roles": [
      {
        "id": 1,
        "name": "Owner",
        "slug": "owner"
      },
      {
        "id": 2,
        "name": "Admin",
        "slug": "admin"
      },
      {
        "id": 5,
        "name": "Customer",
        "slug": "customer"
      }
    ]
  }
}
```

#### Implementation Notes

**Controller**: `Api::V0::PermissionsController#show`  
**Operation**: `Api::V0::Permissions::GetPermissionOperation`  
**Policy**: `PermissionPolicy#show?`  
**Blueprint**: `Api::V0::PermissionBlueprint` (detailed view)

---

## User Roles Endpoints

### 15. Assign Role to User

**POST** `/api/v0/users/:user_id/roles`

Assign one or more roles to a user.

#### Authorization
- Owner/Admin: Can assign roles to users in venue
- Others: Forbidden

#### Request Body

```json
{
  "role_ids": [5, 6]
}
```

#### Response (200 OK)

```json
{
  "success": true,
  "data": {
    "user_id": 15,
    "roles": [
      {
        "id": 5,
        "name": "Customer",
        "slug": "customer",
        "assigned_at": "2026-04-07T14:00:00Z"
      },
      {
        "id": 6,
        "name": "Staff",
        "slug": "staff",
        "assigned_at": "2026-04-07T14:00:00Z"
      }
    ]
  }
}
```

#### Business Rules

1. User can have multiple roles
2. Duplicate role assignments are ignored
3. Audit log entry created with `assigned_by` user

#### Implementation Notes

**Controller**: `Api::V0::UserRolesController#create`  
**Operation**: `Api::V0::UserRoles::AssignRolesOperation`  
**Service**: `Users::AssignRolesService`  
**Policy**: `UserRolePolicy#create?`

---

### 16. Remove Role from User

**DELETE** `/api/v0/users/:user_id/roles/:role_id`

Remove a specific role from a user.

#### Authorization
- Owner/Admin: Can remove roles from users in venue
- Others: Forbidden

#### Response (200 OK)

```json
{
  "success": true,
  "data": {
    "message": "Role removed successfully"
  }
}
```

#### Business Rules

1. Cannot remove the last role from a user
2. Cannot remove Owner role from venue owner
3. Audit log entry created

#### Errors

- **422 Unprocessable Entity**: Cannot remove last role or owner role

#### Implementation Notes

**Controller**: `Api::V0::UserRolesController#destroy`  
**Operation**: `Api::V0::UserRoles::RemoveRoleOperation`  
**Service**: `Users::RemoveRoleService`  
**Policy**: `UserRolePolicy#destroy?`

---

## Role Permissions Endpoints

### 17. Assign Permissions to Role

**POST** `/api/v0/roles/:role_id/permissions`

Assign one or more permissions to a custom role.

#### Authorization
- Owner: Can assign permissions to custom roles
- Others: Forbidden

#### Request Body

```json
{
  "permission_ids": [10, 11, 12, 13, 14]
}
```

#### Response (200 OK)

```json
{
  "success": true,
  "data": {
    "role_id": 6,
    "role_name": "Court Manager",
    "permissions": [
      {
        "id": 10,
        "name": "create:courts",
        "assigned_at": "2026-04-07T15:00:00Z"
      },
      {
        "id": 11,
        "name": "read:courts",
        "assigned_at": "2026-04-07T15:00:00Z"
      }
    ]
  }
}
```

#### Business Rules

1. Can only modify custom roles (system roles are immutable)
2. Duplicate permission assignments are ignored
3. Audit log entry created

#### Errors

- **403 Forbidden**: Cannot modify system roles

#### Implementation Notes

**Controller**: `Api::V0::RolePermissionsController#create`  
**Operation**: `Api::V0::RolePermissions::AssignPermissionsOperation`  
**Service**: `Roles::AssignPermissionsService`  
**Policy**: `RolePermissionPolicy#create?`

---

### 18. Remove Permission from Role

**DELETE** `/api/v0/roles/:role_id/permissions/:permission_id`

Remove a specific permission from a custom role.

#### Authorization
- Owner: Can remove permissions from custom roles
- Others: Forbidden

#### Response (200 OK)

```json
{
  "success": true,
  "data": {
    "message": "Permission removed successfully"
  }
}
```

#### Business Rules

1. Can only modify custom roles
2. Audit log entry created

#### Errors

- **403 Forbidden**: Cannot modify system roles

#### Implementation Notes

**Controller**: `Api::V0::RolePermissionsController#destroy`  
**Operation**: `Api::V0::RolePermissions::RemovePermissionOperation`  
**Service**: `Roles::RemovePermissionService`  
**Policy**: `RolePermissionPolicy#destroy?`

---

## Batch Operations

### 19. Batch Assign Roles

**POST** `/api/v0/users/batch_assign_roles`

Assign roles to multiple users at once.

#### Authorization
- Owner/Admin: Can batch assign roles
- Others: Forbidden

#### Request Body

```json
{
  "user_ids": [15, 16, 17, 18],
  "role_ids": [5, 6]
}
```

#### Response (200 OK)

```json
{
  "success": true,
  "data": {
    "successful": 4,
    "failed": 0,
    "results": [
      {
        "user_id": 15,
        "status": "success",
        "roles_assigned": 2
      },
      {
        "user_id": 16,
        "status": "success",
        "roles_assigned": 2
      }
    ]
  }
}
```

#### Implementation Notes

**Controller**: `Api::V0::UserRolesController#batch_assign`  
**Operation**: `Api::V0::UserRoles::BatchAssignRolesOperation`  
**Service**: `Users::BatchAssignRolesService`  
**Policy**: `UserRolePolicy#batch_assign?`

---

### 20. Batch Assign Permissions

**POST** `/api/v0/roles/batch_assign_permissions`

Assign permissions to multiple custom roles at once.

#### Authorization
- Owner: Can batch assign permissions
- Others: Forbidden

#### Request Body

```json
{
  "role_ids": [6, 7],
  "permission_ids": [10, 11, 12]
}
```

#### Response (200 OK)

```json
{
  "success": true,
  "data": {
    "successful": 2,
    "failed": 0,
    "results": [
      {
        "role_id": 6,
        "role_name": "Court Manager",
        "status": "success",
        "permissions_assigned": 3
      },
      {
        "role_id": 7,
        "role_name": "Booking Manager",
        "status": "success",
        "permissions_assigned": 3
      }
    ]
  }
}
```

#### Implementation Notes

**Controller**: `Api::V0::RolePermissionsController#batch_assign`  
**Operation**: `Api::V0::RolePermissions::BatchAssignPermissionsOperation`  
**Service**: `Roles::BatchAssignPermissionsService`  
**Policy**: `RolePermissionPolicy#batch_assign?`

---

## Services Architecture

All business logic should be extracted into reusable services that can be called from operations across different API versions.

### Service Organization

```
app/services/
├── users/
│   ├── create_service.rb
│   ├── update_service.rb
│   ├── delete_service.rb
│   ├── change_password_service.rb
│   ├── assign_roles_service.rb
│   ├── remove_role_service.rb
│   ├── batch_assign_roles_service.rb
│   ├── search_service.rb
│   └── filter_service.rb
├── roles/
│   ├── create_service.rb
│   ├── update_service.rb
│   ├── delete_service.rb
│   ├── assign_permissions_service.rb
│   ├── remove_permission_service.rb
│   ├── batch_assign_permissions_service.rb
│   └── sync_permissions_service.rb
└── permissions/
    └── filter_service.rb
```

### Service Example: Users::CreateService

```ruby
# app/services/users/create_service.rb
module Users
  class CreateService < BaseService
    def call(params:, venue:, created_by:)
      user = User.new(params)
      user.venue = venue
      
      ActiveRecord::Base.transaction do
        unless user.save
          return failure(user.errors.full_messages)
        end
        
        # Assign default customer role if no roles specified
        if params[:role_ids].blank?
          customer_role = Role.find_by(slug: 'customer')
          user.assign_role(customer_role, assigned_by: created_by)
        end
        
        # Log creation in audit trail
        log_user_creation(user, created_by)
      end
      
      success(user)
    rescue StandardError => e
      failure("Failed to create user: #{e.message}")
    end
    
    private
    
    def log_user_creation(user, created_by)
      # Audit logging logic
      Rails.logger.info "User #{user.id} created by #{created_by.id}"
    end
  end
end
```

### Service Example: Roles::AssignPermissionsService

```ruby
# app/services/roles/assign_permissions_service.rb
module Roles
  class AssignPermissionsService < BaseService
    def call(role:, permission_ids:, assigned_by:)
      return failure("Cannot modify system roles") if role.system_role?
      
      permissions = Permission.where(id: permission_ids)
      return failure("Some permissions not found") if permissions.count != permission_ids.count
      
      ActiveRecord::Base.transaction do
        permissions.each do |permission|
          role.add_permission(permission) unless role.has_permission?(permission.name)
        end
        
        # Log permission changes
        log_permission_assignment(role, permissions, assigned_by)
      end
      
      success(role: role, permissions: permissions)
    rescue StandardError => e
      failure("Failed to assign permissions: #{e.message}")
    end
    
    private
    
    def log_permission_assignment(role, permissions, assigned_by)
      # Audit logging logic
      Rails.logger.info "Permissions #{permissions.pluck(:name)} assigned to role #{role.id} by #{assigned_by.id}"
    end
  end
end
```

---

## Implementation Checklist

### Phase 1: Setup (Day 1)

#### Routes
- [ ] Create `config/routes/api_v0.rb` routes for users
- [ ] Create routes for roles
- [ ] Create routes for permissions
- [ ] Create routes for user_roles
- [ ] Create routes for role_permissions
- [ ] Create batch operation routes

#### Controllers
- [ ] Create `Api::V0::UsersController`
- [ ] Create `Api::V0::RolesController`
- [ ] Create `Api::V0::PermissionsController`
- [ ] Create `Api::V0::UserRolesController`
- [ ] Create `Api::V0::RolePermissionsController`

#### Blueprints
- [ ] Create `Api::V0::UserBlueprint` with views (list, detailed, minimal)
- [ ] Create `Api::V0::RoleBlueprint` with views
- [ ] Create `Api::V0::PermissionBlueprint`
- [ ] Create `Api::V0::UserRoleBlueprint`

---

### Phase 2: Policies (Day 2)

- [ ] Create `UserPolicy` with all actions
- [ ] Create `RolePolicy` with all actions
- [ ] Create `PermissionPolicy` with all actions
- [ ] Create `UserRolePolicy` with all actions
- [ ] Create `RolePermissionPolicy` with all actions
- [ ] Add venue scoping to policies
- [ ] Test all policy methods

---

### Phase 3: Services (Days 3-4)

#### Users Services
- [ ] `Users::CreateService`
- [ ] `Users::UpdateService`
- [ ] `Users::DeleteService`
- [ ] `Users::ChangePasswordService`
- [ ] `Users::AssignRolesService`
- [ ] `Users::RemoveRoleService`
- [ ] `Users::BatchAssignRolesService`
- [ ] `Users::SearchService`
- [ ] `Users::FilterService`

#### Roles Services
- [ ] `Roles::CreateService`
- [ ] `Roles::UpdateService`
- [ ] `Roles::DeleteService`
- [ ] `Roles::AssignPermissionsService`
- [ ] `Roles::RemovePermissionService`
- [ ] `Roles::SyncPermissionsService`
- [ ] `Roles::BatchAssignPermissionsService`

#### Permissions Services
- [ ] `Permissions::FilterService`

---

### Phase 4: Operations (Days 5-6)

#### Users Operations
- [ ] `Api::V0::Users::ListUsersOperation`
- [ ] `Api::V0::Users::GetUserOperation`
- [ ] `Api::V0::Users::CreateUserOperation`
- [ ] `Api::V0::Users::UpdateUserOperation`
- [ ] `Api::V0::Users::DeleteUserOperation`
- [ ] `Api::V0::Users::ChangePasswordOperation`
- [ ] `Api::V0::Users::ToggleStatusOperation`

#### Roles Operations
- [ ] `Api::V0::Roles::ListRolesOperation`
- [ ] `Api::V0::Roles::GetRoleOperation`
- [ ] `Api::V0::Roles::CreateRoleOperation`
- [ ] `Api::V0::Roles::UpdateRoleOperation`
- [ ] `Api::V0::Roles::DeleteRoleOperation`

#### Permissions Operations
- [ ] `Api::V0::Permissions::ListPermissionsOperation`
- [ ] `Api::V0::Permissions::GetPermissionOperation`

#### User Roles Operations
- [ ] `Api::V0::UserRoles::AssignRolesOperation`
- [ ] `Api::V0::UserRoles::RemoveRoleOperation`
- [ ] `Api::V0::UserRoles::BatchAssignRolesOperation`

#### Role Permissions Operations
- [ ] `Api::V0::RolePermissions::AssignPermissionsOperation`
- [ ] `Api::V0::RolePermissions::RemovePermissionOperation`
- [ ] `Api::V0::RolePermissions::BatchAssignPermissionsOperation`

---

### Phase 5: Additional Features (Day 7)

#### Pagination
- [ ] Configure Pagy for API usage
- [ ] Create `app/controllers/concerns/paginable.rb`
- [ ] Add pagination metadata helper
- [ ] Test pagination with various page sizes

#### Audit Logging
- [ ] Create audit log model (if not exists)
- [ ] Add logging to all create/update/delete services
- [ ] Create helper method for audit logging
- [ ] Test audit log entries

#### Search & Filters
- [ ] Implement user search (name, email, phone)
- [ ] Implement role filtering
- [ ] Implement permission filtering by resource/action
- [ ] Test search with various queries

---

### Phase 6: Testing (Days 8-9)

#### Request Specs
- [ ] Users endpoints request specs (all 7 endpoints)
- [ ] Roles endpoints request specs (all 5 endpoints)
- [ ] Permissions endpoints request specs (all 2 endpoints)
- [ ] User roles endpoints request specs
- [ ] Role permissions endpoints request specs
- [ ] Batch operations request specs
- [ ] Test authorization for each endpoint
- [ ] Test venue scoping

#### Service Specs
- [ ] All Users services specs
- [ ] All Roles services specs
- [ ] All Permissions services specs
- [ ] Test success and failure paths
- [ ] Test edge cases

#### Policy Specs
- [ ] UserPolicy specs
- [ ] RolePolicy specs
- [ ] PermissionPolicy specs
- [ ] UserRolePolicy specs
- [ ] RolePermissionPolicy specs

---

### Phase 7: Documentation & Polish (Day 10)

- [ ] Add API documentation comments
- [ ] Create Postman/Insomnia collection
- [ ] Create API examples for frontend team
- [ ] Add rate limiting (if needed)
- [ ] Add API versioning headers
- [ ] Performance testing
- [ ] Security audit

---

## API Best Practices

### 1. Venue Scoping

Always scope queries to the current user's venue:

```ruby
# In operations
def call(params)
  users = current_user.venue.users.where(...)
end
```

### 2. Response Consistency

Always return the same response format:

```ruby
# Success
render json: { success: true, data: ... }, status: :ok

# Error
render json: { success: false, errors: [...] }, status: :unprocessable_entity
```

### 3. Pagination

Use Pagy for consistent pagination:

```ruby
# In controller
@pagy, @users = pagy(users, items: params[:per_page] || 10)

# Response
render json: {
  success: true,
  data: UserBlueprint.render(@users),
  meta: { pagination: pagy_metadata(@pagy) }
}
```

### 4. Authorization

Always check authorization in controllers:

```ruby
def create
  authorize User, :create?
  # ... rest of the code
end
```

### 5. Service Error Handling

Services should return ServiceResult:

```ruby
result = Users::CreateService.call(params: params, venue: venue)
if result.success?
  # Handle success
else
  # Handle failure with result.error
end
```

### 6. Audit Logging

Log all critical actions:

```ruby
# In services
def log_action(user, action, resource)
  AuditLog.create(
    user: user,
    action: action,
    resource_type: resource.class.name,
    resource_id: resource.id,
    ip_address: Current.ip_address,
    user_agent: Current.user_agent
  )
end
```

---

## Next Steps

1. **Review this document** with the team
2. **Start with Phase 1**: Routes, Controllers, Blueprints
3. **Build incrementally**: Complete each phase before moving to next
4. **Test thoroughly**: Write tests as you build
5. **Document examples**: Create Postman collection for frontend team

---

**Questions or Feedback?**

Please review this document and let me know if you need any clarifications or changes before we start implementation.

---

*Last Updated: 2026-04-07*  
*Version: 1.0*
