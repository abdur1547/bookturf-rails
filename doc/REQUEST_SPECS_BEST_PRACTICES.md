# Request Specs Best Practices and Writing Guide

This document provides comprehensive guidelines and a professional prompt template for writing high-quality RSpec request specifications for API endpoints in Rails applications.

## Table of Contents

1. [Core Principles](#core-principles)
2. [Structure and Organization](#structure-and-organization)
3. [Best Practices](#best-practices)
4. [DRY Principles with Let Variables](#dry-principles-with-let-variables)
5. [JSON Response Matching](#json-response-matching)
6. [Test Coverage Requirements](#test-coverage-requirements)
7. [Professional Prompt Template](#professional-prompt-template)

---

## Core Principles

### 1. Comprehensive Coverage
- Test ALL success paths
- Test ALL failure/error paths
- Test edge cases and boundary conditions
- Test authentication and authorization scenarios
- Test validation errors comprehensively

### 2. DRY (Don't Repeat Yourself)
- Use `let` variables for test data at appropriate scope levels
- Define params at root level as `let` variables with default values
- Override `let` variables in nested contexts rather than reassigning
- Use `before` blocks to execute the request once per context
- Never create helper functions/methods inside spec files

### 3. Clear and Descriptive
- Use descriptive context names that explain the scenario
- Write clear test names that describe expected behavior
- Group related tests logically using nested contexts
- Separate SUCCESS and FAILURE paths with clear comments

### 4. Factory-Based Data
- Always use FactoryBot factories for test data
- Never create records manually with `Model.create`
- Define factory data as `let` variables for reusability

---

## Structure and Organization

### File Structure Template

```ruby
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V0::ResourceName", type: :request do
  # ==================================================
  # SHARED TEST DATA SETUP
  # ==================================================
  let(:headers) { { "Content-Type" => "application/json" } }
  
  # Define users with different roles
  let(:owner_user) { create(:user, email: "owner@example.com") }
  let(:admin_user) { create(:user, email: "admin@example.com") }
  
  # Define related test data
  let(:test_resource) { create(:resource, attribute: "value") }
  
  before do
    # Setup that applies to all tests
    owner_user.assign_role(owner_role)
  end
  
  # Helper method for generating auth tokens
  def auth_token_for(user)
    result = Jwt::Issuer.call(user)
    token_data = result.data
    "Bearer #{token_data[:access_token]}"
  end

  # ==================================================
  # GET /api/v0/resources - List resources
  # ==================================================
  describe "GET /api/v0/resources" do
    let(:endpoint) { "/api/v0/resources" }
    let(:query_params) { {} }
    let(:request_headers) { headers }
    
    before do
      params_string = query_params.present? ? "?#{query_params.to_query}" : ""
      get "#{endpoint}#{params_string}", headers: request_headers
    end
    
    # SUCCESS PATHS
    context "when authenticated as owner" do
      let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
      
      it "returns success response" do
        expect(response).to have_http_status(:ok)
      end
      
      # More tests...
    end
    
    # FAILURE PATHS
    context "when not authenticated" do
      let(:request_headers) { headers }
      
      it "returns forbidden status" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
  
  # More endpoint tests...
end
```

### Endpoint Test Organization

For each endpoint, organize tests in this order:

1. **Setup Section** - Define `let` variables for:
   - `endpoint` - The URL path
   - All request parameters (query params, body params, etc.)
   - `request_headers` - Default headers
   
2. **Before Block** - Execute the request once:
   ```ruby
   before do
     get endpoint, params: request_params.to_json, headers: request_headers
   end
   ```

3. **SUCCESS PATHS** - Test all successful scenarios:
   - Valid inputs with full permissions
   - Valid inputs with different user roles
   - Optional parameters
   - Edge cases that should succeed

4. **FAILURE PATHS** - Test all failure scenarios:
   - Missing required parameters
   - Invalid parameter values
   - Unauthorized access (no auth)
   - Forbidden access (insufficient permissions)
   - Not found errors
   - Validation errors

---

## Best Practices

### 1. Use Let Variables for Parameters

**❌ Bad - Repeating params in every test:**
```ruby
it "creates a resource" do
  post endpoint, params: { resource: { name: "Test" } }.to_json, headers: auth_headers
  expect(response).to have_http_status(:created)
end

it "validates name presence" do
  post endpoint, params: { resource: { name: "" } }.to_json, headers: auth_headers
  expect(response).to have_http_status(:unprocessable_entity)
end
```

**✅ Good - Using let variables:**
```ruby
let(:resource_name) { "Test Resource" }
let(:resource_description) { "Test Description" }

let(:request_params) do
  {
    resource: {
      name: resource_name,
      description: resource_description
    }
  }
end

before do
  post endpoint, params: request_params.to_json, headers: request_headers
end

context "with valid parameters" do
  it "creates a resource" do
    expect(response).to have_http_status(:created)
  end
end

context "when name is empty" do
  let(:resource_name) { "" }
  
  it "returns validation error" do
    expect(response).to have_http_status(:unprocessable_entity)
  end
end
```

### 2. Use Before Blocks for Requests

**❌ Bad - Repeating request in every test:**
```ruby
it "returns success" do
  get endpoint, headers: auth_headers
  expect(response).to have_http_status(:ok)
end

it "returns data" do
  get endpoint, headers: auth_headers
  expect(response.parsed_body["data"]).to be_present
end
```

**✅ Good - Request in before block:**
```ruby
before do
  get endpoint, headers: request_headers
end

it "returns success" do
  expect(response).to have_http_status(:ok)
end

it "returns data" do
  expect(response.parsed_body["data"]).to be_present
end
```

### 3. Override Let Variables, Don't Reassign

**❌ Bad - Reassigning variables:**
```ruby
let(:request_params) { { resource: { name: "Test" } } }

it "validates empty name" do
  request_params[:resource][:name] = ""  # DON'T DO THIS
  post endpoint, params: request_params.to_json
  expect(response).to have_http_status(:unprocessable_entity)
end
```

**✅ Good - Override in nested context:**
```ruby
let(:resource_name) { "Test Resource" }
let(:request_params) { { resource: { name: resource_name } } }

context "when name is empty" do
  let(:resource_name) { "" }  # Override the let variable
  
  it "returns validation error" do
    expect(response).to have_http_status(:unprocessable_entity)
  end
end
```

### 4. Use Factories for Test Data

**❌ Bad - Manual record creation:**
```ruby
let(:user) do
  User.create!(
    email: "test@example.com",
    password: "password123",
    first_name: "Test"
  )
end
```

**✅ Good - Using factories:**
```ruby
let(:user) { create(:user, email: "test@example.com") }
```

### 5. Don't Create Helper Methods in Spec Files

**❌ Bad - Helper methods in spec:**
```ruby
def make_request(params)
  post endpoint, params: params.to_json, headers: auth_headers
end

def expect_success
  expect(response).to have_http_status(:ok)
end
```

**✅ Good - Use let variables and before blocks:**
```ruby
let(:request_params) { { resource: { name: "Test" } } }

before do
  post endpoint, params: request_params.to_json, headers: request_headers
end

it "returns success" do
  expect(response).to have_http_status(:ok)
end
```

---

## DRY Principles with Let Variables

### Query Parameters Pattern

```ruby
describe "GET /api/v0/resources" do
  let(:endpoint) { "/api/v0/resources" }
  let(:query_params) { {} }  # Default: no params
  
  before do
    params_string = query_params.present? ? "?#{query_params.to_query}" : ""
    get "#{endpoint}#{params_string}", headers: request_headers
  end
  
  context "with type filter" do
    let(:query_params) { { type: "active" } }  # Override
    
    it "filters by type" do
      # Request already made with filter
      expect(response).to have_http_status(:ok)
    end
  end
  
  context "with sort parameter" do
    let(:query_params) { { sort: "name" } }  # Override
    
    it "sorts by name" do
      data = response.parsed_body["data"]
      names = data.map { |r| r["name"] }
      expect(names).to eq(names.sort)
    end
  end
end
```

### Body Parameters Pattern

```ruby
describe "POST /api/v0/resources" do
  let(:endpoint) { "/api/v0/resources" }
  let(:request_headers) { headers }
  
  # Define each parameter as a separate let variable
  let(:resource_name) { "New Resource" }
  let(:resource_description) { "Description" }
  let(:resource_type) { "standard" }
  let(:permission_ids) { [permission1.id, permission2.id] }
  
  # Compose params from individual variables
  let(:request_params) do
    {
      resource: {
        name: resource_name,
        description: resource_description,
        type: resource_type,
        permission_ids: permission_ids
      }
    }
  end
  
  before do
    post endpoint, params: request_params.to_json, headers: request_headers
  end
  
  context "with valid parameters" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    
    it "creates the resource" do
      expect(response).to have_http_status(:created)
    end
  end
  
  context "when name is empty" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:resource_name) { "" }  # Override just this param
    
    it "returns validation error" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
  
  context "when permission_ids is empty" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:permission_ids) { [] }  # Override just this param
    
    it "creates resource with no permissions" do
      expect(response).to have_http_status(:created)
      expect(Resource.last.permissions.count).to eq(0)
    end
  end
end
```

### Headers Pattern

```ruby
let(:request_headers) { headers }  # Default: no auth

context "when authenticated as owner" do
  let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
  
  # All tests in this context use owner auth
end

context "when not authenticated" do
  # Uses default headers (no auth)
  
  it "returns forbidden" do
    expect(response).to have_http_status(:forbidden)
  end
end
```

---

## JSON Response Matching

We use the [json_matchers](https://github.com/thoughtbot/json_matchers) gem for validating JSON responses against JSON Schema definitions. This provides a declarative, maintainable way to verify API response structures.

### Setup

The gem is configured in `spec/support/json_matchers.rb` and JSON schemas are stored in `spec/support/api/schemas/`.

### Using JSON Schema Matchers (Preferred)

**✅ Recommended - Using schema validation:**
```ruby
it "returns JSON response matching schema" do
  expect(response).to match_json_schema("roles/show_response")
end

it "returns success status and matches schema" do
  expect(response).to have_http_status(:ok)
  expect(response).to match_json_schema("roles/index_response")
end

it "returns error response matching schema" do
  expect(response).to have_http_status(:unprocessable_entity)
  expect(response).to match_json_schema("error_response")
end
```

### Creating JSON Schemas

JSON schemas should be placed in `spec/support/api/schemas/` organized by resource:

```
spec/support/api/schemas/
├── error_response.json          # Generic error response schema
├── success_response.json        # Generic success response schema
└── roles/
    ├── index_response.json      # GET /api/v0/roles
    ├── show_response.json       # GET /api/v0/roles/:id
    └── create_response.json     # POST /api/v0/roles
```

**Example Schema (roles/show_response.json):**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["success", "data"],
  "properties": {
    "success": {
      "type": "boolean",
      "enum": [true]
    },
    "data": {
      "$ref": "#/definitions/role_detail"
    }
  },
  "definitions": {
    "role_detail": {
      "type": "object",
      "required": ["id", "name", "slug", "description", "is_custom"],
      "properties": {
        "id": { "type": "integer" },
        "name": { "type": "string" },
        "slug": { "type": "string" },
        "description": { "type": "string" },
        "is_custom": { "type": "boolean" },
        "created_at": { "type": "string", "format": "date-time" },
        "updated_at": { "type": "string", "format": "date-time" }
      }
    }
  }
}
```

### Manual JSON Matching (Alternative)

For simple validations or when you need to test specific values, manual matchers can still be used:

### Basic Structure Matching

```ruby
it "returns JSON response with correct structure" do
  expect(response.parsed_body).to match(
    "success" => true,
    "data" => be_a(Hash)
  )
end
```

### Detailed Attribute Matching

```ruby
it "includes complete resource attributes" do
  data = response.parsed_body["data"]
  expect(data).to match(
    "id" => be_a(Integer),
    "name" => "Resource Name",
    "slug" => be_a(String),
    "description" => be_a(String),
    "is_active" => be_in([true, false]),
    "created_at" => be_a(String),
    "updated_at" => be_a(String)
  )
end
```

### Array Response Matching

```ruby
it "returns array of resources" do
  data = response.parsed_body["data"]
  expect(data).to be_an(Array)
  expect(data.length).to be >= 1
end

it "each resource has correct structure" do
  data = response.parsed_body["data"]
  expect(data).to all(include(
    "id" => be_a(Integer),
    "name" => be_a(String),
    "type" => be_a(String)
  ))
end
```

### Nested Data Matching

```ruby
it "includes associated permissions with complete structure" do
  data = response.parsed_body["data"]
  expect(data["permissions"]).to be_an(Array)
  expect(data["permissions"].length).to eq(2)
  
  permission_data = data["permissions"].first
  expect(permission_data).to include(
    "id" => be_a(Integer),
    "name" => be_a(String),
    "resource" => be_a(String),
    "action" => be_a(String)
  )
end
```

### Error Response Matching

```ruby
it "returns error response structure" do
  expect(response.parsed_body).to match(
    "success" => false,
    "errors" => be_present
  )
end

it "includes validation errors" do
  errors = response.parsed_body["errors"]
  expect(errors).to be_a(Hash)
  expect(errors).to have_key("name")
end
```

---

## Test Coverage Requirements

### For Each Endpoint, Test:

#### 1. GET Requests (Index/List)
- ✅ Success with proper authentication
- ✅ Response structure (JSON format)
- ✅ Data attributes completeness
- ✅ Query parameter filters
- ✅ Sorting options
- ✅ Pagination (if implemented)
- ✅ Empty results
- ✅ Unauthorized access (no auth)
- ✅ Forbidden access (insufficient permissions)
- ✅ Invalid query parameters

#### 2. GET Requests (Show/Detail)
- ✅ Success with proper authentication
- ✅ Response structure
- ✅ Complete resource details
- ✅ Associated/nested resources
- ✅ Resource not found
- ✅ Invalid ID format
- ✅ Unauthorized access
- ✅ Forbidden access

#### 3. POST Requests (Create)
- ✅ Success with valid data
- ✅ Created status (201)
- ✅ Response includes created resource
- ✅ Resource persisted to database
- ✅ Associated records created
- ✅ Default values applied
- ✅ Missing required fields
- ✅ Invalid field values
- ✅ Duplicate data (uniqueness)
- ✅ Invalid associations
- ✅ Unauthorized access
- ✅ Forbidden access
- ✅ Malformed request body

#### 4. PATCH/PUT Requests (Update)
- ✅ Success with valid data
- ✅ Partial updates (individual fields)
- ✅ Full updates (all fields)
- ✅ Associated records updated
- ✅ Unchanged fields remain same
- ✅ Invalid field values
- ✅ Duplicate data (uniqueness)
- ✅ Resource not found
- ✅ Unauthorized access
- ✅ Forbidden access
- ✅ Protected resources (e.g., system records)

#### 5. DELETE Requests (Destroy)
- ✅ Success with no associations
- ✅ Resource removed from database
- ✅ Cannot delete with dependencies
- ✅ Resource not found
- ✅ Invalid ID format
- ✅ Unauthorized access
- ✅ Forbidden access
- ✅ Protected resources

### Authentication/Authorization Tests

For each endpoint, test:
1. No authentication (missing token)
2. Invalid token
3. Expired token
4. Each user role (owner, admin, staff, customer, etc.)
5. Correct permissions granted
6. Insufficient permissions denied

---

## Professional Prompt Template

Use this prompt when requesting request specs for a controller:

```
Create comprehensive RSpec request specifications for the [ControllerName] controller endpoints.

## Requirements:

### Structure & Organization:
1. Follow the existing patterns in the codebase (reference: spec/requests/api/v0/auth/reset_password_request_spec.rb)
2. Use clear section comments to separate different endpoints
3. Group tests into SUCCESS PATHS and FAILURE PATHS
4. Use descriptive context names

### DRY Principles:
1. Define ALL request parameters as `let` variables at the root level of each endpoint describe block
2. For body params: Define each field as a separate let variable with a default value
3. For query params: Define as a hash that can be overridden in contexts
4. Define headers as `let(:request_headers)` with default value
5. Use ONE `before` block to execute the request, which uses the let variables
6. Override let variables in nested contexts (never reassign)
7. DO NOT create helper functions or methods inside the spec file
8. Use FactoryBot factories for all test data

### Before Block Pattern:
```ruby
before do
  post endpoint, params: request_params.to_json, headers: request_headers
end
```

### Test Coverage:
1. Test ALL success paths (all valid input combinations)
2. Test ALL failure paths (all validation errors, auth errors, not found, etc.)
3. Test edge cases (empty arrays, nil values, boundary conditions, etc.)
4. Test all user roles and permission levels
5. Test with valid, invalid, missing, and expired authentication tokens

### JSON Response Verification:
1. **Preferred:** Use JSON Schema validation with `json_matchers` gem:
   - `expect(response).to match_json_schema("resource/show_response")`
   - Create schemas in `spec/support/api/schemas/` directory
   - Define reusable schemas with `$ref` and `definitions`
2. **Alternative:** Use RSpec matchers for specific value checks:
   - `expect(response.parsed_body).to match(hash_structure)`
   - `be_a(Type)`, `be_an(Array)`, `be_present`
3. Verify nested data structures and associations
4. Check array element structures with `.first` or `.all`
5. Verify error response formats match `error_response.json` schema

### Specific Tests for Each HTTP Method:

**GET (Index):**
- Returns success status and correct structure
- Returns all expected records
- Includes all attributes in response
- Query parameter filters work correctly
- Sorting options work
- Auth/permission variations

**GET (Show):**
- Returns success with correct resource
- Includes all attributes and nested associations
- Returns 404 for non-existent resources
- Handles invalid ID formats
- Auth/permission variations

**POST (Create):**
- Returns 201 status
- Creates record in database
- Returns created resource in response
- Assigns associations correctly
- Validates required fields
- Validates uniqueness constraints
- Handles invalid data gracefully
- Auth/permission variations

**PATCH/PUT (Update):**
- Returns 200 status
- Updates specified fields
- Keeps unchanged fields intact
- Updates associations
- Validates constraints
- Returns 404 for non-existent
- Cannot update protected resources
- Auth/permission variations

**DELETE (Destroy):**
- Returns 200 status
- Removes record from database
- Cannot delete with dependencies
- Returns 404 for non-existent
- Cannot delete protected resources
- Auth/permission variations

### Example Format:
```ruby
describe "POST /api/v0/resources" do
  let(:endpoint) { "/api/v0/resources" }
  let(:request_headers) { headers }
  let(:resource_name) { "Default Name" }
  let(:resource_type) { "standard" }
  
  let(:request_params) do
    {
      resource: {
        name: resource_name,
        type: resource_type
      }
    }
  end
  
  before do
    post endpoint, params: request_params.to_json, headers: request_headers
  end
  
  # SUCCESS PATHS
  context "when authenticated as owner" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    
    it "returns created status" do
      expect(response).to have_http_status(:created)
    end
    
    it "matches the create response schema" do
      expect(response).to match_json_schema("resources/create_response")
    end
    
    # More success tests...
  end
  
  # FAILURE PATHS
  context "when name is empty" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:resource_name) { "" }
    
    it "returns validation error" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
    
    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end
end
```

Generate complete, production-ready request specs following these requirements exactly.
```

---

## Common Patterns and Examples

### Testing Different User Roles

```ruby
describe "GET /api/v0/resources" do
  let(:endpoint) { "/api/v0/resources" }
  let(:request_headers) { headers }
  
  before do
    get endpoint, headers: request_headers
  end
  
  context "when authenticated as owner" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    
    it "returns success" do
      expect(response).to have_http_status(:ok)
    end
  end
  
  context "when authenticated as admin" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }
    
    it "returns success" do
      expect(response).to have_http_status(:ok)
    end
  end
  
  context "when authenticated as customer" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(customer_user)) }
    
    it "returns forbidden" do
      expect(response).to have_http_status(:forbidden)
    end
  end
end
```

### Testing Validation Errors

```ruby
describe "POST /api/v0/resources" do
  let(:endpoint) { "/api/v0/resources" }
  let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
  let(:resource_name) { "Valid Name" }
  let(:resource_email) { "valid@example.com" }
  
  let(:request_params) do
    {
      resource: {
        name: resource_name,
        email: resource_email
      }
    }
  end
  
  before do
    post endpoint, params: request_params.to_json, headers: request_headers
  end
  
  context "when name is blank" do
    let(:resource_name) { "" }
    
    it "returns unprocessable entity" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
    
    it "includes name error" do
      expect(response.parsed_body["errors"]).to have_key("name")
    end
  end
  
  context "when email is invalid" do
    let(:resource_email) { "invalid-email" }
    
    it "returns unprocessable entity" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
    
    it "includes email error" do
      expect(response.parsed_body["errors"]).to have_key("email")
    end
  end
end
```

### Testing Associations

```ruby
describe "POST /api/v0/roles" do
  let(:endpoint) { "/api/v0/roles" }
  let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
  let(:role_name) { "Manager" }
  let(:permission_ids) { [permission1.id, permission2.id] }
  
  let(:request_params) do
    {
      role: {
        name: role_name,
        permission_ids: permission_ids
      }
    }
  end
  
  before do
    post endpoint, params: request_params.to_json, headers: request_headers
  end
  
  it "assigns permissions to role" do
    new_role = Role.find_by(name: role_name)
    expect(new_role.permissions.pluck(:id)).to match_array(permission_ids)
  end
  
  it "includes permissions in response" do
    data = response.parsed_body["data"]
    expect(data["permissions"]).to be_an(Array)
    expect(data["permissions"].length).to eq(2)
  end
  
  context "with invalid permission IDs" do
    let(:permission_ids) { [99999, 88888] }
    
    it "returns validation error" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
```

---

## Checklist for Request Specs

Before submitting request specs, ensure:

- [ ] All endpoints have comprehensive tests
- [ ] Used `let` variables for all parameters
- [ ] Used `before` blocks for requests
- [ ] Overridden `let` variables, not reassigned
- [ ] No helper methods created in spec file
- [ ] Used factories for all test data
- [ ] Tested all success paths
- [ ] Tested all failure paths
- [ ] Tested all user roles
- [ ] Tested authentication scenarios
- [ ] Added JSON schema validation with `json_matchers`
- [ ] Created JSON schema files for all response types
- [ ] Tested edge cases
- [ ] Clear context and test names
- [ ] Proper section comments
- [ ] Tests are independent and can run in any order

---

## Additional Resources

- [RSpec Best Practices](https://betterspecs.org/)
- [FactoryBot Documentation](https://github.com/thoughtbot/factory_bot)
- [RSpec Matchers](https://relishapp.com/rspec/rspec-expectations/docs/built-in-matchers)
- [Rails Testing Guide](https://guides.rubyonrails.org/testing.html)
- [JSON Matchers](https://github.com/thoughtbot/json_matchers) - Schema-based JSON response validation
- [JSON Schema](https://json-schema.org/) - Understanding JSON Schema format

---

## Summary

Writing good request specs is about:
1. **Coverage** - Test everything
2. **DRY** - Use let variables and before blocks
3. **Clarity** - Descriptive names and organization
4. **Factories** - Always use FactoryBot
5. **Verification** - Schema-based JSON validation with `json_matchers`

Follow these guidelines to create maintainable, comprehensive, and professional request specifications.
