class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      # Unique identifier
      t.string :booking_number, null: false

      # References
      t.references :user, null: false, foreign_key: true
      t.references :court, null: false, foreign_key: true
      t.references :venue, null: false, foreign_key: true # Denormalized

      # Time slot
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.integer :duration_minutes, null: false

      # Status
      t.string :status, null: false, default: 'confirmed'

      # Payment (MVP: cash only)
      t.decimal :total_amount, precision: 10, scale: 2, default: 0
      t.string :payment_method
      t.string :payment_status, default: 'pending'
      t.decimal :paid_amount, precision: 10, scale: 2, default: 0

      # Notes
      t.text :notes

      # Cancellation
      t.datetime :cancelled_at
      t.references :cancelled_by, foreign_key: { to_table: :users }
      t.text :cancellation_reason

      # Check-in
      t.datetime :checked_in_at
      t.references :checked_in_by, foreign_key: { to_table: :users }

      # Creation tracking
      t.references :created_by, foreign_key: { to_table: :users }
      t.string :created_by_role # customer, staff, owner

      # Walk-in support
      t.string :walk_in_name # For anonymous walk-in customers

      # Price snapshot (protects against future pricing changes)
      t.decimal :price_at_booking, precision: 10, scale: 2

      # Share token for shareable booking URLs
      t.string :share_token # Unique token for /b/:share_token
      t.boolean :deferred_link_claimed, default: false, null: false # Deep link redemption

      t.timestamps
    end

    # Indexes
    add_index :bookings, :booking_number, unique: true
    add_index :bookings, [ :court_id, :start_time, :end_time ]
    add_index :bookings, [ :venue_id, :start_time ]
    add_index :bookings, :status
    add_index :bookings, [ :start_time, :end_time ]
    add_index :bookings, :share_token, unique: true

    # Check constraints
    add_check_constraint :bookings,
      'end_time > start_time',
      name: 'end_time_after_start_time'

    add_check_constraint :bookings,
      'duration_minutes > 0',
      name: 'positive_duration'

    add_check_constraint :bookings,
      'paid_amount >= 0',
      name: 'non_negative_paid_amount'

    add_check_constraint :bookings,
      'paid_amount <= total_amount',
      name: 'paid_not_exceeding_total'
  end
end
