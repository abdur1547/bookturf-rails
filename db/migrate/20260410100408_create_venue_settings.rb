class CreateVenueSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :venue_settings do |t|
      t.references :venue, null: false, foreign_key: true, index: { unique: true }

      # Slot Configuration
      t.integer :minimum_slot_duration, null: false, default: 60
      t.integer :maximum_slot_duration, null: false, default: 180
      t.integer :slot_interval, null: false, default: 30

      # Booking Rules
      t.integer :advance_booking_days, default: 30
      t.boolean :requires_approval, default: false, null: false
      t.integer :cancellation_hours

      # Localization
      t.string :timezone, null: false, default: 'Asia/Karachi'
      t.string :currency, default: 'PKR'

      t.timestamps
    end

    # Check constraints
    add_check_constraint :venue_settings,
      'minimum_slot_duration > 0',
      name: 'minimum_slot_duration_positive'

    add_check_constraint :venue_settings,
      'maximum_slot_duration >= minimum_slot_duration',
      name: 'maximum_greater_than_minimum'

    add_check_constraint :venue_settings,
      'slot_interval > 0',
      name: 'slot_interval_positive'
  end
end
