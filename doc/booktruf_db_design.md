**BookTruf**

Database Layer — Design Document

*Stack: Ruby on Rails · PostgreSQL · Shrine · Solid Queue*

Version 1.0  ·  April 2026


# **1. Overview & Design Decisions**
This document defines every database model, field, index, and enum for the BookTruf v1 platform. It is the authoritative reference for the Rails data layer before migrations are written.

## **1.1 Technology Choices**

|**Concern**|**Decision**|
| :- | :- |
|**Database**|PostgreSQL — leverages native array columns, partial indexes, and JSONB for Shrine data|
|**Auth (Admin)**|Rails built-in has\_secure\_password on User model — bcrypt digest stored in password\_digest|
|**Auth (API)**|JWT — access token (short-lived) + refresh token (long-lived, stored in refresh\_tokens table)|
|**File storage**|Shrine gem — image metadata stored as JSONB in \*\_data columns; S3 for production, disk for dev|
|**Background jobs**|Solid Queue — DB-backed queue; notification jobs, reminder jobs, invite expiry jobs|
|**Soft deletes**|None — hard deletes only. Audit logs provide the paper trail for bookings|
|**Enums**|Rails enum backed by PostgreSQL integer column — future-proof, checked at DB and app layer|
|**Timestamps**|All tables include created\_at and updated\_at (Rails default). Key events also store explicit UTC timestamps|

## **1.2 Role Model**
All humans are rows in the single users table. Role is derived from relationships, not a column:

→  A user who owns a Venue (venue.owner\_id = user.id) is an Owner.

→  A user who has a row in venue\_staff is a Staff Member for that venue.

→  Any other authenticated user is a Customer.

→  The same person can be a Customer AND a Staff Member at the same time (different accounts are not required).

## **1.3 Shrine Image Strategy**
Shrine stores file metadata as JSONB in a \*\_data column alongside the record. No separate attachments table is needed.

venues.images\_data  — array of Shrine JSON objects (up to 10 venue images)

courts.images\_data  — array of Shrine JSON objects (up to 8 court images)

reviews.photos\_data — array of Shrine JSON objects (up to 5 review photos)

users.avatar\_data   — single Shrine JSON object

⚑  *Each \*\_data column stores the full Shrine metadata including storage key, filename, size, mime\_type, and any derivatives (thumbnails). The Rails model calls include ImageUploader::Attachment(:images) which handles serialisation automatically.*


# **2. Enums**
All enums are stored as integers in PostgreSQL and declared with Rails enum. This keeps the DB compact while Rails provides human-readable symbols.

**BookingStatus  (table: bookings, column: status)**

0 → pending  |  1 → confirmed  |  2 → cancelled  |  3 → no\_show

*pending = awaiting owner/staff confirmation (manual approval venues). confirmed = slot is locked in. cancelled = cancelled by any party. no\_show = slot passed without the customer appearing (future use, set manually by staff).*

**VenueStaffStatus  (table: venue\_staff, column: status)**

0 → pending  |  1 → active  |  2 → removed

*pending = invite sent, user has not yet accepted. active = user accepted and is linked. removed = owner revoked access (soft state — row kept for audit trail).*

**BookingCreatedByRole  (table: bookings, column: created\_by\_role)**

0 → customer  |  1 → staff  |  2 → owner

*Records who initiated the booking. Walk-in bookings created by staff will have created\_by\_role = staff.*

**AuditAction  (table: audit\_logs, column: action)**

0 → created  |  1 → confirmed  |  2 → cancelled  |  3 → updated

**AuditPerformedByRole  (table: audit\_logs, column: performed\_by\_role)**

0 → customer  |  1 → staff  |  2 → owner  |  3 → system

*system is used for automated actions such as Solid Queue reminder jobs or expiry sweepers.*

**NotificationChannel  (table: notifications, column: channel)**

0 → push  |  1 → email

**NotificationStatus  (table: notifications, column: status)**

0 → pending  |  1 → sent  |  2 → failed

**DayOfWeek  (table: pricing\_rules & operating\_hours, column: day\_of\_week)**

0 → sunday  |  1 → monday  |  2 → tuesday  |  3 → wednesday  |  4 → thursday  |  5 → friday  |  6 → saturday

*Matches Ruby Date::DAYNAMES index. One row per day per court/venue — no arrays or bitmasks.*

**OnboardingStep  (table: venues, column: onboarding\_step)**

0 → not\_started  |  1 → venue\_info  |  2 → operating\_hours  |  3 → courts  |  4 → completed

*Tracks wizard progress. Owner is shown the incomplete step on next login.*


# **3. Model Definitions**

## **3.1  users**
Central identity table shared by customers, owners, and staff. Role is inferred from relationships, not stored here.

|**Column**|**Type**|**Constraints**|**Notes**|
| :- | :- | :- | :- |
|**id**|bigint|PK, not null|Rails default bigserial primary key|
|**email**|string|not null, unique|Downcased before save. Used for login and invites|
|**password\_digest**|string|not null|bcrypt via has\_secure\_password. NULL for OAuth-only users|
|**first\_name**|string|not null||
|**last\_name**|string|not null||
|**avatar\_data**|jsonb|nullable|Shrine single image attachment|
|**google\_uid**|string|nullable, unique|Google OAuth sub claim. NULL if email signup|
|**apple\_uid**|string|nullable, unique|Apple Sign In sub. NULL in v1 (owner web only)|
|**email\_verified**|boolean|not null, default: false|Set to true after email link click or OAuth|
|**email\_verified\_at**|datetime|nullable|UTC timestamp of verification|
|**preferred\_city\_id**|bigint|FK → cities, nullable|Saved city preference. NULL until user picks one|
|**preferred\_town\_id**|bigint|FK → towns, nullable|Optional sub-area preference within city|
|**push\_token**|string|nullable|FCM/APNS device token. Updated on each app launch|
|**notify\_day\_of**|boolean|not null, default: true|Notification preference: 8 AM day-of reminder|
|**notify\_30\_min**|boolean|not null, default: true|Notification preference: 30-min before reminder|
|**notify\_email\_bookings**|boolean|not null, default: true|Owner: email on new booking / cancellation|
|**notify\_email\_reviews**|boolean|not null, default: true|Owner: email when new review is posted|
|**created\_at**|datetime|not null||
|**updated\_at**|datetime|not null||

## **3.2  refresh\_tokens**
Stores JWT refresh tokens for API authentication. The raw token is returned to the client once and never stored — only the SHA-256 digest is kept.

|**Column**|**Type**|**Constraints**|**Notes**|
| :- | :- | :- | :- |
|**id**|bigint|PK, not null||
|**user\_id**|bigint|FK → users, not null||
|**token\_digest**|string|not null, unique|SHA-256 of the raw token. Raw token returned once to client, never stored|
|**expires\_at**|datetime|not null|Typically 30 days from issue|
|**revoked\_at**|datetime|nullable|Set on logout or password reset to invalidate early|
|**created\_at**|datetime|not null||

## **3.3  cities**
Admin-seeded lookup table. Customers pick a city on first launch. Courts and venues are scoped to a city.

|**Column**|**Type**|**Constraints**|**Notes**|
| :- | :- | :- | :- |
|**id**|bigint|PK, not null||
|**name**|string|not null, unique|e.g. Lahore, Karachi, Peshawar|
|**country**|string|not null, default: "Pakistan"|Ready for future multi-country expansion|
|**is\_active**|boolean|not null, default: true|Hidden from discovery if false|
|**created\_at**|datetime|not null||
|**updated\_at**|datetime|not null||

## **3.4  towns**
Sub-areas within a city (e.g. DHA, Gulberg). Used for filtering on the home and court listing screens. Unique name per city enforced at DB level.

|**Column**|**Type**|**Constraints**|**Notes**|
| :- | :- | :- | :- |
|**id**|bigint|PK, not null||
|**city\_id**|bigint|FK → cities, not null||
|**name**|string|not null|e.g. DHA, Gulberg, Saddar. Unique within city|
|**is\_active**|boolean|not null, default: true||
|**created\_at**|datetime|not null||
|**updated\_at**|datetime|not null||
⚑  *Add a unique index on [city\_id, name] to prevent duplicate town names within the same city.*

## **3.5  venues**
One venue per owner (v1 constraint enforced by unique index on owner\_id). Holds location info and onboarding progress.

|**Column**|**Type**|**Constraints**|**Notes**|
| :- | :- | :- | :- |
|**id**|bigint|PK, not null||
|**owner\_id**|bigint|FK → users, not null, unique|unique enforces one venue per owner in v1|
|**city\_id**|bigint|FK → cities, not null||
|**town\_id**|bigint|FK → towns, not null||
|**name**|string|not null|Display name of the venue|
|**street\_address**|string|not null|Street-level address|
|**latitude**|decimal|nullable|Precision 10, scale 7. Set via geocoding after address save|
|**longitude**|decimal|nullable|Precision 10, scale 7|
|**images\_data**|jsonb|nullable|Shrine array of venue images (max 10). Ordered array.|
|**onboarding\_step**|integer|not null, default: 0|Enum: 0=not\_started … 4=completed|
|**timezone**|string|not null, default: 'Asia/Karachi'|IANA timezone identifier. Used by availability service to generate local-time slots|
|**currency**|string|not null, default: 'PKR'|ISO 4217 currency code. Displayed in pricing responses|
|**is\_active**|boolean|not null, default: false|Set to true after onboarding\_step = completed|
|**created\_at**|datetime|not null||
|**updated\_at**|datetime|not null||

## **3.6  operating\_hours**
Seven rows per venue (one per day of week). Created during onboarding Step 2. Changed hours take effect immediately; they do not retroactively affect existing bookings.

|**Column**|**Type**|**Constraints**|**Notes**|
| :- | :- | :- | :- |
|**id**|bigint|PK, not null||
|**venue\_id**|bigint|FK → venues, not null||
|**day\_of\_week**|integer|not null|Enum 0=sunday … 6=saturday. One row per day|
|**is\_open**|boolean|not null, default: true|false = venue closed on this day|
|**opens\_at**|time|nullable|Stored as time-only (no date). NULL if is\_open = false|
|**closes\_at**|time|nullable|NULL if is\_open = false. Must be > opens\_at|
|**created\_at**|datetime|not null||
|**updated\_at**|datetime|not null||
⚑  *Unique index on [venue\_id, day\_of\_week] — a venue cannot have two rows for the same day.*

## **3.7  venue\_closures**
Ad-hoc datetime window closures for an entire venue (e.g. public holiday, private event). Blocks all courts for any slot that overlaps the window. Does NOT auto-cancel existing bookings — owner must do that manually (app warns them).

|**Column**|**Type**|**Constraints**|**Notes**|
| :- | :- | :- | :- |
|**id**|bigint|PK, not null||
|**venue\_id**|bigint|FK → venues, not null||
|**title**|string|not null|Short label shown to staff, e.g. "Public Holiday", "Private Event"|
|**description**|string|nullable|Optional longer note for internal context|
|**start\_time**|datetime|not null|UTC start of the closure window|
|**end\_time**|datetime|not null|UTC end of the closure window. Must be > start\_time (check constraint)|
|**created\_by\_id**|bigint|FK → users, nullable|Owner or staff who created the closure|
|**created\_at**|datetime|not null||
|**updated\_at**|datetime|not null||

## **3.8  courts**
Each court belongs to a venue and defines the bookable unit: sport type, slot duration, pricing mode, and images.

|**Column**|**Type**|**Constraints**|**Notes**|
| :- | :- | :- | :- |
|**id**|bigint|PK, not null||
|**venue\_id**|bigint|FK → venues, not null||
|**name**|string|not null|e.g. Court A, Padel 1. Unique per sport within venue|
|**sport**|string|not null|Stored as string: cricket, football, badminton, tennis, padel, basketball, squash, volleyball. Easy to extend by adding to seed list|
|**minimum\_slot\_duration**|integer|not null, default: 60|Shortest bookable slot in minutes. Must be > 0. (check constraint)|
|**maximum\_slot\_duration**|integer|not null, default: 180|Longest bookable slot in minutes. Must be >= minimum\_slot\_duration. (check constraint)|
|**slot\_interval**|integer|not null, default: 30|Step size in minutes between slot start times. Must be > 0. (check constraint)|
|**requires\_approval**|boolean|not null, default: false|true = bookings require owner/staff confirmation before they are confirmed|
|**images\_data**|jsonb|nullable|Shrine array (max 8 images)|
|**qr\_code\_url**|string|nullable|URL of generated QR PNG stored on S3. Set after court creation by background job|
|**is\_active**|boolean|not null, default: true|Paused courts are hidden from discovery|
|**created\_at**|datetime|not null||
|**updated\_at**|datetime|not null||
⚑  *sport is a plain string column. Add a Rails validation for inclusion in a constant list rather than a DB enum — easier to extend without a migration.*

## **3.9  pricing\_rules**
Flexible per-court pricing. Each row covers one day of week and a time window. Multiple rows cover multiple days or time bands. The slot price is resolved at booking time by finding the matching rule.

|**Column**|**Type**|**Constraints**|**Notes**|
| :- | :- | :- | :- |
|**id**|bigint|PK, not null||
|**court\_id**|bigint|FK → courts, not null||
|**day\_of\_week**|integer|not null|Enum 0=sunday…6=saturday. One row per day. Same price on multiple days = multiple rows|
|**from\_time**|time|not null|Start of pricing window (time-only)|
|**to\_time**|time|not null|End of pricing window. Must be > from\_time|
|**price\_per\_slot**|decimal|not null|Precision 10, scale 2. Price in PKR for one slot of court.slot\_duration|
|**created\_at**|datetime|not null||
|**updated\_at**|datetime|not null||
⚑  *Overlap validation (same day, overlapping time window on the same court) must be enforced in Rails — PostgreSQL range exclusion constraints can also be added for belt-and-suspenders safety.*

## **3.10  court\_closures**
Blocks specific datetime windows on a court (e.g. maintenance, tournament). Any slot that overlaps the window is treated as unavailable.

|**Column**|**Type**|**Constraints**|**Notes**|
| :- | :- | :- | :- |
|**id**|bigint|PK, not null||
|**court\_id**|bigint|FK → courts, not null||
|**starts\_at**|datetime|not null|UTC. Blocks all slots that overlap this window|
|**ends\_at**|datetime|not null|UTC. Must be > starts\_at|
|**reason**|string|nullable|e.g. Maintenance, Tournament|
|**created\_by\_id**|bigint|FK → users, not null|Owner or staff who created the closure|
|**created\_at**|datetime|not null||
|**updated\_at**|datetime|not null||

## **3.11  bookings**
The core transactional record. Every booked slot — whether from the app, staff walk-in, or owner — creates one row here.

|**Column**|**Type**|**Constraints**|**Notes**|
| :- | :- | :- | :- |
|**id**|bigint|PK, not null||
|**court\_id**|bigint|FK → courts, not null||
|**user\_id**|bigint|FK → users, not null|The customer who holds the booking|
|**slot\_start**|datetime|not null|UTC. Exact start of the booked slot|
|**slot\_end**|datetime|not null|UTC. Derived: slot\_start + court.slot\_duration|
|**status**|integer|not null, default: 0|Enum: pending/confirmed/cancelled/no\_show|
|**price\_at\_booking**|decimal|not null|Precision 10, scale 2. Snapshot of price at time of booking. Protects against future pricing changes|
|**created\_by\_role**|integer|not null|Enum: customer/staff/owner — who initiated the booking|
|**created\_by\_id**|bigint|FK → users, not null|User record of whoever created the booking|
|**walk\_in\_name**|string|nullable|Free-text name for walk-in customers who have no account. NULL for regular app bookings|
|**cancellation\_reason**|string|nullable|Optional reason text filled by staff/owner when cancelling|
|**cancelled\_at**|datetime|nullable|UTC timestamp of cancellation|
|**cancelled\_by\_id**|bigint|FK → users, nullable|User who cancelled. NULL if not yet cancelled|
|**confirmed\_at**|datetime|nullable|UTC timestamp of confirmation|
|**confirmed\_by\_id**|bigint|FK → users, nullable|User who confirmed (NULL for instant-mode venues)|
|**share\_token**|string|nullable, unique|Random token used in shareable URL /b/[token]. Generated on booking creation|
|**deferred\_link\_claimed**|boolean|not null, default: false|Set true when a recipient installs app via share link and the booking is added to their history|
|**created\_at**|datetime|not null||
|**updated\_at**|datetime|not null||
⚑  *slot\_end is stored explicitly (not just derived) so queries like "find all bookings overlapping window X" can use a simple range index without runtime arithmetic.*

⚑  *price\_at\_booking is a snapshot — if the owner later changes pricing, past bookings are unaffected.*

⚑  *share\_token is generated with SecureRandom.urlsafe\_base64(12) on creation. Exposed as /b/:share\_token.*

## **3.12  audit\_logs**
Immutable event log for every booking state change. No updated\_at column — rows are never modified after insert.

|**Column**|**Type**|**Constraints**|**Notes**|
| :- | :- | :- | :- |
|**id**|bigint|PK, not null||
|**booking\_id**|bigint|FK → bookings, not null||
|**action**|integer|not null|Enum: created/confirmed/cancelled/updated|
|**performed\_by\_id**|bigint|FK → users, nullable|NULL only when performed\_by\_role = system|
|**performed\_by\_role**|integer|not null|Enum: customer/staff/owner/system|
|**previous\_status**|integer|nullable|Booking status integer before the action|
|**new\_status**|integer|nullable|Booking status integer after the action|
|**snapshot**|jsonb|nullable|Full booking attributes at the time of the action. Immutable record for audit purposes|
|**notes**|text|nullable|Free-text. e.g. cancellation reason entered by staff|
|**created\_at**|datetime|not null|Immutable — do not add updated\_at to this table|

⚑  *snapshot stores the full booking attributes as JSONB at the moment of the action — this gives owners a complete picture even if booking data changes later.*

## **3.13  reviews**
One review per booking. Customers submit after the slot has passed. Owners can reply once.

|**Column**|**Type**|**Constraints**|**Notes**|
| :- | :- | :- | :- |
|**id**|bigint|PK, not null||
|**booking\_id**|bigint|FK → bookings, not null, unique|unique: one review per booking|
|**user\_id**|bigint|FK → users, not null|Reviewer. Denormalised from booking for quick queries|
|**court\_id**|bigint|FK → courts, not null|Denormalised from booking for quick aggregation|
|**rating**|integer|not null|Integer 1–5. Validated in Rails (inclusion: 1..5)|
|**body**|text|nullable|Written review text. Optional per spec|
|**photos\_data**|jsonb|nullable|Shrine array (max 5 photos)|
|**owner\_reply**|text|nullable|Owner response text. NULL until owner replies|
|**owner\_replied\_at**|datetime|nullable|UTC timestamp of reply|
|**created\_at**|datetime|not null||
|**updated\_at**|datetime|not null||
⚑  *court\_id and user\_id are denormalised from the booking for efficient aggregation (average rating per court, reviews per user) without always joining through bookings.*

## **3.14  venue\_staff**
Links users to venues with a staff role. Also handles the invite lifecycle — user\_id is NULL until the invitee signs up and claims the invite token.

|**Column**|**Type**|**Constraints**|**Notes**|
| :- | :- | :- | :- |
|**id**|bigint|PK, not null||
|**venue\_id**|bigint|FK → venues, not null||
|**user\_id**|bigint|FK → users, nullable|NULL while invite is pending (user may not exist yet)|
|**invited\_email**|string|not null|Email the invite was sent to. Used to link user on signup|
|**status**|integer|not null, default: 0|Enum: pending/active/removed|
|**invite\_token**|string|not null, unique|Secure random token (hex 32). Included in invite email link|
|**invite\_token\_expires\_at**|datetime|not null|Typically 7 days from invite creation|
|**invited\_by\_id**|bigint|FK → users, not null|Owner who sent the invite|
|**joined\_at**|datetime|nullable|UTC when user accepted the invite|
|**removed\_at**|datetime|nullable|UTC when owner removed the staff member|
|**created\_at**|datetime|not null||
|**updated\_at**|datetime|not null||
⚑  *When a new user signs up with an email matching invited\_email, the app checks venue\_staff for a pending row and auto-links them (sets user\_id, status = active, joined\_at).*

⚑  *Unique index on [venue\_id, invited\_email] prevents duplicate invites to the same email.*

## **3.15  notifications**
Source-of-truth for every push and email notification. Solid Queue jobs read pending rows and update status after delivery.

|**Column**|**Type**|**Constraints**|**Notes**|
| :- | :- | :- | :- |
|**id**|bigint|PK, not null||
|**user\_id**|bigint|FK → users, not null|Recipient|
|**booking\_id**|bigint|FK → bookings, nullable|Associated booking if applicable|
|**channel**|integer|not null|Enum: push / email|
|**status**|integer|not null, default: 0|Enum: pending / sent / failed|
|**title**|string|not null|Push notification title or email subject|
|**body**|text|not null|Push notification body or email text content|
|**template\_key**|string|nullable|e.g. booking\_confirmed, day\_of\_reminder. Used to look up HTML email template|
|**payload**|jsonb|nullable|Extra data passed to push notification (e.g. booking\_id for deep link on tap)|
|**sent\_at**|datetime|nullable|UTC when successfully delivered|
|**failed\_at**|datetime|nullable|UTC of last failure|
|**failure\_reason**|string|nullable|Error message from push/email provider|
|**solid\_queue\_job\_id**|string|nullable|Reference to the Solid Queue job that will/did send this notification|
|**created\_at**|datetime|not null||
|**updated\_at**|datetime|not null||
⚑  *Day-of and 30-min reminders are scheduled by a Solid Queue job when a booking is confirmed. If the booking is later cancelled, the job is discarded by querying notifications by booking\_id and status = pending.*


# **4. Indexes**
All foreign keys get an index automatically via Rails. The following are additional indexes required for query performance and uniqueness constraints.

## **users**

|**Columns**|**Type**|**Purpose**|
| :- | :- | :- |
|**email**|UNIQUE|Login lookup and invite matching|
|**google\_uid**|UNIQUE|OAuth login lookup|
|**apple\_uid**|UNIQUE|OAuth login lookup|
|**preferred\_city\_id**|BTREE|Filter users by city (future analytics)|

## **refresh\_tokens**

|**Columns**|**Type**|**Purpose**|
| :- | :- | :- |
|**token\_digest**|UNIQUE|Token lookup on every API request — must be O(1)|
|**user\_id**|BTREE|Revoke all tokens for a user on password reset|
|**expires\_at**|BTREE|Solid Queue sweep job to delete expired tokens|

## **towns**

|**Columns**|**Type**|**Purpose**|
| :- | :- | :- |
|**city\_id, name**|UNIQUE|Prevent duplicate town names within a city|

## **venues**

|**Columns**|**Type**|**Purpose**|
| :- | :- | :- |
|**owner\_id**|UNIQUE|Enforce one venue per owner (v1)|
|**city\_id**|BTREE|Discovery: all venues in a city|
|**town\_id**|BTREE|Discovery: all venues in a town|
|**is\_active**|BTREE|Partial — filter to active venues only|

## **operating\_hours**

|**Columns**|**Type**|**Purpose**|
| :- | :- | :- |
|**venue\_id, day\_of\_week**|UNIQUE|One row per day per venue|

## **venue\_closures**

|**Columns**|**Type**|**Purpose**|
| :- | :- | :- |
|**venue\_id, start\_time, end\_time**|BTREE|Check if venue is closed during a given window (range query)|
|**start\_time, end\_time**|BTREE|Cross-venue closure range queries|

## **courts**

|**Columns**|**Type**|**Purpose**|
| :- | :- | :- |
|**venue\_id, sport, name**|UNIQUE|Unique court name per sport within a venue|
|**venue\_id, is\_active**|BTREE|List active courts for a venue|
|**sport**|BTREE|Discovery filter by sport type|

## **pricing\_rules**

|**Columns**|**Type**|**Purpose**|
| :- | :- | :- |
|**court\_id, day\_of\_week**|BTREE|Fetch all pricing rules for a court on a given day|

## **court\_closures**

|**Columns**|**Type**|**Purpose**|
| :- | :- | :- |
|**court\_id, starts\_at, ends\_at**|BTREE|Check if a court is closed during a given window (range query)|

## **bookings**

|**Columns**|**Type**|**Purpose**|
| :- | :- | :- |
|**court\_id, slot\_start, slot\_end**|BTREE|Core availability check: find overlapping bookings for a court|
|**court\_id, status**|BTREE|Dashboard: pending bookings per court|
|**user\_id, status**|BTREE|My Bookings screen: upcoming/past/cancelled tabs|
|**share\_token**|UNIQUE|Shareable booking URL lookup|
|**slot\_start**|BTREE|Solid Queue: find bookings needing day-of / 30-min reminders|
|**created\_by\_id**|BTREE|Staff activity report|

## **audit\_logs**

|**Columns**|**Type**|**Purpose**|
| :- | :- | :- |
|**booking\_id**|BTREE|Fetch all audit events for a booking (detail panel)|
|**performed\_by\_id**|BTREE|Staff activity report: all actions by a staff member|
|**created\_at**|BTREE|Date-range filtering in reports|

## **reviews**

|**Columns**|**Type**|**Purpose**|
| :- | :- | :- |
|**booking\_id**|UNIQUE|One review per booking|
|**court\_id**|BTREE|Aggregate rating per court|
|**user\_id**|BTREE|User review history|

## **venue\_staff**

|**Columns**|**Type**|**Purpose**|
| :- | :- | :- |
|**venue\_id, invited\_email**|UNIQUE|Prevent duplicate invites to same email per venue|
|**venue\_id, status**|BTREE|List active/pending staff for a venue|
|**invite\_token**|UNIQUE|Invite acceptance lookup|
|**user\_id, venue\_id**|UNIQUE|Prevent same user being added twice (once linked)|

## **notifications**

|**Columns**|**Type**|**Purpose**|
| :- | :- | :- |
|**user\_id, status**|BTREE|Find pending notifications for a user|
|**booking\_id**|BTREE|Cancel pending notifications when booking is cancelled|
|**status, created\_at**|BTREE|Solid Queue sweep: retry failed notifications|


# **5. Model Relationships**

|**From**|**Relationship**|**To**|**Notes**|
| :- | :- | :- | :- |
|**User**|has\_one|Venue (as owner)|via venues.owner\_id — one venue per owner in v1|
|**User**|has\_many|Bookings|as the customer (bookings.user\_id)|
|**User**|has\_many|VenueStaff|rows where user\_id = self.id — staff memberships|
|**User**|has\_many|Venues (through VenueStaff)|venues the user is staff at|
|**User**|has\_many|RefreshTokens|all issued refresh tokens|
|**User**|has\_many|Notifications||
|**User**|belongs\_to|City (preferred)|optional preferred city|
|**User**|belongs\_to|Town (preferred)|optional preferred town|
|**City**|has\_many|Towns||
|**City**|has\_many|Venues||
|**Town**|belongs\_to|City||
|**Town**|has\_many|Venues||
|**Venue**|belongs\_to|User (owner)|via owner\_id|
|**Venue**|belongs\_to|City||
|**Venue**|belongs\_to|Town||
|**Venue**|has\_many|Courts||
|**Venue**|has\_many|OperatingHours|7 rows per venue|
|**Venue**|has\_many|VenueClosures|ad-hoc full-day closures|
|**Venue**|has\_many|VenueStaff|staff memberships|
|**Court**|belongs\_to|Venue||
|**Court**|has\_many|PricingRules||
|**Court**|has\_many|CourtClosures||
|**Court**|has\_many|Bookings||
|**Court**|has\_many|Reviews|denormalised FK for aggregation|
|**Booking**|belongs\_to|Court||
|**Booking**|belongs\_to|User (customer)|via user\_id|
|**Booking**|belongs\_to|User (created\_by)|via created\_by\_id|
|**Booking**|has\_many|AuditLogs||
|**Booking**|has\_one|Review|one review per booking|
|**Booking**|has\_many|Notifications||
|**Review**|belongs\_to|Booking||
|**Review**|belongs\_to|User|reviewer|
|**Review**|belongs\_to|Court|denormalised|
|**AuditLog**|belongs\_to|Booking||
|**AuditLog**|belongs\_to|User (performed\_by)|nullable — null for system actions|
|**VenueStaff**|belongs\_to|Venue||
|**VenueStaff**|belongs\_to|User|nullable until invite accepted|
|**Notification**|belongs\_to|User||
|**Notification**|belongs\_to|Booking|optional|


# **6. Slot Availability Resolution Logic**
This section documents how the backend resolves available slots for a court on a given date — this is the most complex query in the system.

## **Step 1 — Check venue is open**
Query operating\_hours WHERE venue\_id = ? AND day\_of\_week = [day of requested date] AND is\_open = true. If no row or is\_open = false → no slots.

Check venue\_closures WHERE venue\_id = ? AND start\_time < [day end] AND end\_time > [day start]. If any row overlaps the day → no slots.

## **Step 2 — Generate candidate slots**
Using opens\_at and closes\_at from operating\_hours and the per-court slot config (court.minimum\_slot\_duration as default slot size, court.slot\_interval as step), generate an ordered array of slot windows:

slots = (opens\_at .. closes\_at - slot\_duration).step(slot\_interval)

Each slot is a [slot\_start, slot\_end] pair in UTC. slot\_duration defaults to court.minimum\_slot\_duration but can be overridden by the caller (up to court.maximum\_slot\_duration).

## **Step 3 — Remove court closures**
Query court\_closures WHERE court\_id = ? AND starts\_at < slot\_end AND ends\_at > slot\_start. Remove any generated slot that overlaps a closure window.

## **Step 4 — Remove booked slots**
Query bookings WHERE court\_id = ? AND status IN (pending, confirmed) AND slot\_start < [window\_end] AND slot\_end > [window\_start]. Remove any generated slot that overlaps an existing active booking.

## **Step 5 — Attach pricing**
For each remaining slot, find the matching pricing\_rule WHERE court\_id = ? AND day\_of\_week = ? AND from\_time <= slot\_start AND to\_time >= slot\_end. Attach price\_per\_slot to the slot object.

⚑  *If no pricing rule matches a slot, that slot should be excluded from results (treat as unconfigured). The Rails model should validate that pricing rules cover all operating hours to prevent gaps.*

## **Step 6 — Return**
Return the array of available slots with [slot\_start, slot\_end, price, court\_id] for the API response.


# **7. Background Jobs (Solid Queue)**
All jobs are defined as ActiveJob classes and enqueued into Solid Queue. The following jobs are needed in v1.

|**Job**|**Trigger**|**Scheduled at**|**What it does**|
| :- | :- | :- | :- |
|**SendNotificationJob**|Booking event|Immediately|Reads a notification row and dispatches push (FCM) or email. Updates status to sent or failed.|
|**BookingDayOfReminderJob**|Booking confirmed|8:00 AM on booking date (UTC+5)|Creates a push notification row for the customer and enqueues SendNotificationJob. Skipped if booking is cancelled.|
|**Booking30MinReminderJob**|Booking confirmed|30 min before slot\_start|Same as above but 30-min copy. Checks notify\_30\_min preference before sending.|
|**ExpireInviteTokensJob**|Scheduled (daily)|Daily at 02:00 UTC|Finds venue\_staff rows where status = pending AND invite\_token\_expires\_at < now. Sets status = removed and clears token.|
|**ExpireRefreshTokensJob**|Scheduled (daily)|Daily at 03:00 UTC|Deletes refresh\_token rows where expires\_at < now and revoked\_at IS NULL.|
|**QrCodeGenerationJob**|Court created|Immediately (async)|Generates a QR PNG for the court URL, uploads to S3, sets court.qr\_code\_url.|
|**OwnerEmailNotificationJob**|Booking created / cancelled / review posted|Immediately|Sends transactional email to the venue owner. Respects notify\_email\_\* preferences on the owner user.|

⚑  *Reminder jobs store a reference to their Solid Queue job ID in the notifications.solid\_queue\_job\_id column. If a booking is cancelled, a cancellation hook looks up pending notifications by booking\_id and discards the queued jobs before they fire.*


# **8. Auth Architecture**

## **8.1  Password Auth (API — customers & owners)**
POST /api/v1/auth/signup — Creates a User row, sends verification email, returns access + refresh tokens.

POST /api/v1/auth/signin — Verifies password via authenticate (has\_secure\_password), issues tokens.

POST /api/v1/auth/refresh — Accepts refresh token, verifies digest against refresh\_tokens table, issues new access token.

POST /api/v1/auth/reset\_password — Two-step: request (sends email with token), confirm (verifies token, updates password\_digest, revokes all refresh tokens).

## **8.2  Token Design**

|**Token**|**TTL**|**Storage**|
| :- | :- | :- |
|**Access token (JWT)**|15 minutes|Returned in response body. Client stores in memory (not localStorage). Sent as Authorization: Bearer <token>.|
|**Refresh token**|30 days|Returned in response body. Client stores in secure storage (Keychain on iOS, Keystore on Android). SHA-256 digest stored in refresh\_tokens table.|
|**Email verify token**|24 hours|Signed JWT with purpose: email\_verification. Not stored in DB — verified by signature + expiry.|
|**Password reset token**|1 hour|Signed JWT with purpose: password\_reset. Same approach as email verify.|

## **8.3  Admin Panel Auth (Rails built-in)**
The Rails admin panel uses Rails built-in authentication (http\_basic\_authenticate\_with or the Rails 8 generator-based authentication). It operates on the same users table but only allows access to users who are linked as a venue owner, or to a separate admin boolean flag if you add one later.

⚑  *Consider adding an is\_admin boolean to users if you need a platform-level admin panel for managing cities, towns, and reviewing flagged content. This is out of v1 scope but easy to add.*


# **9. OG (Open Graph) Image Generation — Explained**
You asked to skip this in v1 but wanted an explanation. Here is how it works so you can plan for it later.

## **What is an OG image?**
When you share a URL on WhatsApp, iMessage, or Twitter, the platform fetches the page and reads special <meta> tags. One of those tags — og:image — points to an image that gets rendered as the link preview. For BookTruf this means when a customer shares their booking link, the recipient sees a rich card with the sport illustration, venue name, and date/time — not just a plain URL.

## **Why is it complex?**
The image must be dynamically generated per booking (different venue, sport, date for every booking). You cannot pre-generate it. This requires a service that renders HTML/CSS to a PNG on the fly.

## **How it works (for v1 planning)**

1\. Customer shares a booking. The URL is booktruf.com/b/[share\_token].

2\. When WhatsApp fetches that URL, your Next.js page responds with og:image pointing to an image endpoint, e.g. booktruf.com/api/og?booking=[token].

3\. That endpoint (Next.js API route) uses a library called @vercel/og (or similar) to render a React component to a PNG in ~50ms.

4\. The PNG includes the sport name, venue, date, and a fun tagline. WhatsApp shows it as the preview.

## **DB Impact (v1 — none)**
No DB changes needed. The image endpoint reads the booking and venue data it already has. When you are ready to implement it, it is purely a Next.js frontend task — no Rails or schema changes required.


# **10. Open Questions & Future Schema Notes**

|**Topic**|**Note**|
| :- | :- |
|**Admin panel users**|Add is\_admin boolean to users if a BookTruf ops team needs to manage cities, towns, flag reviews, or suspend venues. A simple scope + before\_action in the admin controller is enough for v1.|
|**Multi-court simultaneous bookings**|Current model: one booking per slot per court. If a court can host multiple groups simultaneously, add a capacity integer to courts and change the availability query to count bookings vs capacity.|
|**Waitlist**|Add a waitlists table (court\_id, user\_id, slot\_start, slot\_end, notified\_at). When a booking is cancelled, a job checks the waitlist and notifies the next person.|
|**Multi-venue owners**|Remove the unique index on venues.owner\_id and ensure all venue-scoped queries are filtered correctly. No other schema changes needed.|
|**In-app payments**|Add a payments table (booking\_id, amount, currency, provider, provider\_ref, status, paid\_at). Mark bookings with payment\_status. Bigger scope — plan as a separate milestone.|
|**Review moderation**|Add is\_flagged boolean and flagged\_reason to reviews. Admin panel shows flagged reviews for manual action.|
|**Recurring bookings**|Add a recurring\_booking\_group\_id (self-referential FK) to bookings so a set of recurring slots can be managed together.|
|**Phone number / SMS**|Add phone and phone\_verified columns to users when SMS reminders are introduced.|


