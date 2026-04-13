# Booking Availability Endpoint Plan

## Goal
Provide a public API endpoint that returns all valid slots for all courts in a venue, including pricing and availability state.

The endpoint should:
- be public (no authentication required)
- return data for one venue
- respect `venue_settings` for slot generation
- account for `venue_operating_hours`
- account for `court_closures`
- account for existing confirmed bookings
- calculate slot pricing from `pricing_rules`
- optionally include booked slots with a flag
- allow filtering by date, court type, court, and slot duration

---

## Endpoint design

### Route
`GET /api/v0/venues/:venue_id/availability`

### Query parameters
- `start_date` (required) - first local date string for the venue, e.g. `2026-04-16`
- `end_date` (optional) - last local date string for the venue; defaults to `start_date`
- `duration_minutes` (optional) - requested slot length; defaults to `venue_settings.minimum_slot_duration`
- `court_type_id` (optional) - restrict availability to courts of a single court type
- `court_id` (optional) - restrict availability to a single court
- `include_booked` (optional, boolean) - when `true`, return both available and blocked slots; when `false` or omitted, return available-only slots
- `from_time` (optional) - local time boundary to start searching each day, e.g. `08:00`
- `to_time` (optional) - local time boundary to end searching each day, e.g. `22:00`
- `timezone` (optional) - ignored for venue-specific request; venue timezone is authoritative

### Response shape
```json
{
  "success": true,
  "data": {
    "venue_id": 1,
    "date": "2026-04-16",
    "timezone": "Asia/Karachi",
    "court_availability": [
      {
        "court_id": 10,
        "court_name": "Court 1",
        "slots": [
          {
            "start_time": "2026-04-16T09:00:00+05:00",
            "end_time": "2026-04-16T10:00:00+05:00",
            "duration_minutes": 60,
            "price_per_hour": "1200.0",
            "total_amount": "1200.0",
            "available": true,
            "booked": false,
            "booking_status": null
          },
          {
            "start_time": "2026-04-16T10:00:00+05:00",
            "end_time": "2026-04-16T11:00:00+05:00",
            "duration_minutes": 60,
            "price_per_hour": "1500.0",
            "total_amount": "1500.0",
            "available": false,
            "booked": true,
            "booking_status": "confirmed"
          }
        ]
      }
    ]
  }
}
```

### Field definitions
- `start_time`, `end_time`: ISO 8601 local timestamps based on the venue timezone
- `duration_minutes`: integer
- `price_per_hour`: string or decimal, computed from pricing rules
- `total_amount`: string or decimal, `price_per_hour * duration_hours`
- `available`: whether the slot is valid and not blocked
- `booked`: whether the slot intersects a confirmed booking or closure
- `booking_status`: `confirmed` or `closed` if the slot is blocked by court closure; `null` if available

> Timestamps are returned in the venue local timezone.

---

## Business rules

### Slot generation and validation
1. Use `venue_settings.timezone` as the authoritative timezone.
2. Generate slots across the requested `start_date` to `end_date` range.
3. Use `from_time` / `to_time` to limit the search window each day, defaulting to the venue operating hours range.
4. Slot duration must fit in `venue_settings.minimum_slot_duration`, `maximum_slot_duration`, and be a multiple of `venue_settings.slot_interval`.
5. Only generate slots that fit fully within a single operating day and within venue operating hours.
6. Do not generate slots on days when `venue_operating_hours.is_closed` is `true`.
7. Exclude slots that overlap any court closure for the same court or the same venue.
8. Exclude slots that overlap existing confirmed bookings for the same court.

### Booking conflict rules
- A slot is blocked if any `Booking` exists for the court where:
  - `status = confirmed`
  - and the booking overlaps the slot range
- Optionally the endpoint can still return the blocked slot when `include_booked=true`.

### Court closure rules
- A slot is blocked if any `CourtClosure` exists for the court where the closure overlaps the slot.
- If the closure is for the whole venue, also block the slot.

### Pricing rules
- Price is calculated per slot using `PricingRule.price_for(court.court_type, slot_start_time)`.
- `total_amount = price_per_hour * (duration_minutes / 60.0)`.
- If a slot crosses a pricing boundary, the MVP will use the rule for the slot start time.
- Future enhancement: split cross-boundary slots into multiple priced segments.

### Available vs booked mode
- Default behavior: return available slots only (`include_booked=false` or omitted).
- With `include_booked=true`: return all candidate slots plus blocked slots.
- The response includes `available` and `booked` flags so frontend can render both.

---

## Implementation plan

### 1. Routes
Add a public route in `config/routes/api_v0.rb`:
```ruby
resources :venues, only: API_ONLY_ROUTES do
  member do
    get :availability
  end
end
```

### 2. Controller
Add an `availability` action to `Api::V0::VenuesController`:
- Accept `params.to_unsafe_h`
- Call `Api::V0::Venues::ListAvailabilityOperation`
- Render success/failure using existing API response helpers
- Skip authentication for this action

### 3. Operation
Create `app/operations/api/v0/venues/list_availability_operation.rb`.
Responsibilities:
- Validate params with a contract
- Load venue and venue settings
- Convert `date`, `from_time`, `to_time` in venue timezone
- Load operating hours for the requested day
- Load courts for the venue, optionally filtered by `court_type_id` and/or `court_id`
- Delegate slot generation to a service
- Serialize the results

### 4. Service
Create `app/services/venues/availability_service.rb` or `bookings/availability_service.rb`.
Responsibilities:
- Generate candidate slots for each court
- Apply operating hours, minimum/maximum slot duration, and slot interval
- Apply court closures and existing bookings
- Mark each slot as available/booked
- Calculate pricing for each slot
- Return structured availability data per court

### 5. Supporting helpers and models
Potential helpers:
- `VenueOperatingHour#within_hours?(start_time, end_time)`
- `CourtClosure#overlaps?(start_time, end_time)`
- `Booking#overlaps?(start_time, end_time)`
- `Booking.slot_available?(...)` may be reused for candidate verification

If needed, add a dedicated availability helper on `Court` or `Venue` for filtering closures and bookings.

### 6. Blueprint / Serializer
Because returned data is a custom structure, implement serialization in the operation or create a blueprint such as `Api::V0::CourtAvailabilityBlueprint`.
The response should include:
- court metadata
- array of availability slots
- pricing and availability flags

### 7. Specs
Create request specs for the new endpoint:
- public access should succeed
- returns only available slots by default
- returns booked slots when `include_booked=true`
- respects `venue_settings.slot_interval`, `minimum_slot_duration`, and `maximum_slot_duration`
- respects venue operating hours and closed days
- respects court closures
- respects existing confirmed bookings
- calculates `price_per_hour` and `total_amount`

Optional service/unit specs:
- generate slots correctly for a court
- block slots for court closures and bookings
- price slots based on pricing rules

---

## Detailed logic flow

### A. Request validation
Required:
- `venue_id`
- `start_date`

Optional:
- `end_date`
- `duration_minutes`
- `court_id`
- `include_booked`
- `from_time`
- `to_time`

Validation rules:
- `start_date` and `end_date` must be valid local date strings
- `end_date` defaults to `start_date` if omitted
- `start_date` must be on or before `end_date`
- `duration_minutes` must be between `minimum_slot_duration` and `maximum_slot_duration` and a multiple of `slot_interval`
- `from_time` / `to_time` must parse to valid local times
- if both are provided, `from_time < to_time`

### B. Determine the search window
1. Use `venue_settings.timezone`.
2. Use the requested `date` as the local date in that timezone.
3. If `from_time` / `to_time` are missing, use the venue operating hours for that day.
4. Validate that the final window is inside operating hours.
5. Build candidate slots starting at `from_time`, incrementing by `slot_interval`, ensuring each slot ends before or at `to_time`.

### C. Candidate slot generation
For each court:
- Build time windows from the search window using the interval
- Each candidate slot has:
  - `start_time`
  - `end_time = start_time + duration_minutes`
  - `duration_minutes`
- Reject slots that cross the operating boundary or the end of the day

### D. Blocked slot detection
Mark a candidate slot as blocked if any of these are true:
- overlapping `CourtClosure` for the same court or venue
- overlapping confirmed `Booking` for the same court
- venue is closed that day

### E. Pricing calculation
For each candidate slot:
- `price_per_hour = PricingRule.price_for(court.court_type, slot_start_time)`
- `total_amount = (price_per_hour * duration_minutes / 60.0).round(2)`
- use `slot_start_time` in venue timezone for pricing selection

### F. Response filtering
- If `include_booked=false`: return only slots where `available == true`
- If `include_booked=true`: return all slots
- Always include slot-level status metadata for clarity

---

## Open questions for MVP clarity
1. Should the endpoint support a multi-day range, or only a single `date` per request?
2. When a slot overlaps a non-confirmed booking (`cancelled`, `no_show`, `completed`), should it remain available?
3. Should the API return timestamps in venue-local ISO format, UTC, or both?
4. Do we want to expose booked slot details beyond `booked: true` and `booking_status`? For privacy, the MVP should keep it minimal.
5. Should cross-pricing-boundary slots be priced by start time only, or do we want true segment pricing in this MVP?

---

## MVP assumptions
- `PricingRule.price_for` is the pricing source and is used per slot start time.
- Only `confirmed` bookings block a slot.
- Venue operating hours and court closures are authoritative for availability.
- The endpoint is public and does not require authentication.
- The generated slots are for a single venue and single date.
- `minimum_slot_duration`, `maximum_slot_duration`, and `slot_interval` are enforced.

---

## Implementation artifacts

### New files
- `config/routes/api_v0.rb` update
- `app/controllers/api/v0/venues_controller.rb` add `availability`
- `app/operations/api/v0/venues/list_availability_operation.rb`
- `app/services/venues/availability_service.rb`
- `app/blueprints/api/v0/court_availability_blueprint.rb` (optional)
- `spec/requests/api/v0/venues_availability_spec.rb`

### Optional helpers
- `app/models/booking.rb` overlap helper
- `app/models/court_closure.rb` overlap helper
- `app/models/venue_operating_hour.rb` scheduler helper

---

## Next step
Please confirm whether you want:
- `start_date` / `end_date` date range support
- strictly `confirmed` bookings only block slots
- venue local time output format
- booked slots should include minimal metadata only
