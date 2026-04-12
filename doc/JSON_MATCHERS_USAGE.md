# JSON Matchers Usage Example

This file demonstrates how to use `json_matchers` gem in request specs.

## Before (Manual Matching)

```ruby
it "returns success response with correct structure" do
  expect(response).to have_http_status(:ok)
  expect(response.parsed_body).to match(
    "success" => true,
    "data" => be_a(Hash)
  )
end

it "includes complete role attributes" do
  data = response.parsed_body["data"]
  expect(data).to match(
    "id" => be_a(Integer),
    "name" => be_a(String),
    "slug" => be_a(String),
    "description" => be_a(String),
    "is_custom" => be_in([true, false]),
    "created_at" => be_a(String),
    "updated_at" => be_a(String),
    "permissions" => be_an(Array),
    "users" => be_an(Array)
  )
end
```

## After (Using json_matchers)

```ruby
it "returns success response matching schema" do
  expect(response).to have_http_status(:ok)
  expect(response).to match_json_schema("roles/show_response")
end
```

## Benefits

1. **DRY** - Schema defined once, reused across multiple tests
2. **Maintainable** - Schema changes in one place
3. **Comprehensive** - Validates all fields, types, and structure
4. **Readable** - Clear intent in test code
5. **Reusable** - Same schema for similar endpoints
6. **Standards-based** - Uses JSON Schema standard

## Creating Schemas

### 1. Create schema file: `spec/support/api/schemas/roles/show_response.json`

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
        "updated_at": { "type": "string", "format": "date-time" },
        "permissions": {
          "type": "array",
          "items": { "$ref": "#/definitions/permission" }
        },
        "users": {
          "type": "array",
          "items": { "$ref": "#/definitions/user" }
        }
      }
    },
    "permission": {
      "type": "object",
      "required": ["id", "name", "resource", "action"],
      "properties": {
        "id": { "type": "integer" },
        "name": { "type": "string" },
        "resource": { "type": "string" },
        "action": { "type": "string" },
        "description": { "type": "string" }
      }
    },
    "user": {
      "type": "object",
      "required": ["id", "name"],
      "properties": {
        "id": { "type": "integer" },
        "name": { "type": "string" }
      }
    }
  }
}
```

### 2. Use in tests

```ruby
describe "GET /api/v0/roles/:id" do
  # ... setup code ...
  
  context "when authenticated as owner" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    
    it "returns success response matching schema" do
      expect(response).to have_http_status(:ok)
      expect(response).to match_json_schema("roles/show_response")
    end
    
    # You can still do specific value checks when needed
    it "returns the correct role" do
      data = response.parsed_body["data"]
      expect(data["id"]).to eq(test_role.id)
      expect(data["name"]).to eq("Test Role")
    end
  end
  
  context "when role not found" do
    let(:role_id) { 99999 }
    
    it "returns error response matching schema" do
      expect(response).to have_http_status(:not_found)
      expect(response).to match_json_schema("error_response")
    end
  end
end
```

## Common Schemas to Create

### 1. Generic Schemas (reusable across resources)
- `error_response.json` - For all error responses
- `success_response.json` - For simple success messages

### 2. Resource-Specific Schemas
- `resources/index_response.json` - For list endpoints
- `resources/show_response.json` - For detail endpoints
- `resources/create_response.json` - For create endpoints (201)
- `resources/update_response.json` - For update endpoints

## Tips

1. **Use `$ref` for reusable definitions** - Define common objects once in definitions
2. **Mark required fields explicitly** - Use `"required": ["field1", "field2"]`
3. **Be specific with types** - Use `"enum"` for boolean success fields
4. **Format validation** - Use `"format": "date-time"` for timestamps
5. **Test both success and error schemas** - Cover all response types
6. **Keep schemas DRY** - Extract common patterns into definitions

## Schema Validation vs Manual Matching

Use **schema validation** when:
- ✅ Testing API response structure/format
- ✅ Ensuring consistent response format across endpoints
- ✅ Validating all fields are present and correct type
- ✅ Documenting expected response format

Use **manual matching** when:
- ✅ Testing specific business logic values
- ✅ Checking computed/calculated values
- ✅ Verifying relationship data (counts, specific IDs)
- ✅ Testing dynamic content

**Best practice:** Combine both approaches!
```ruby
it "returns success response matching schema" do
  expect(response).to match_json_schema("roles/show_response")
end

it "returns the correct role data" do
  data = response.parsed_body["data"]
  expect(data["id"]).to eq(test_role.id)
  expect(data["permissions"].count).to eq(2)
end
```
