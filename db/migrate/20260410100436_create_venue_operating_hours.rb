class CreateVenueOperatingHours < ActiveRecord::Migration[8.1]
  def change
    create_table :venue_operating_hours do |t|
      t.references :venue, null: false, foreign_key: true

      t.integer :day_of_week, null: false # 0=Sunday, 6=Saturday
      t.time :opens_at, null: false
      t.time :closes_at, null: false
      t.boolean :is_closed, default: false, null: false

      t.timestamps
    end

    # Indexes
    add_index :venue_operating_hours, [ :venue_id, :day_of_week ], unique: true

    # Check constraints
    add_check_constraint :venue_operating_hours,
      'day_of_week BETWEEN 0 AND 6',
      name: 'valid_day_of_week'
  end
end
