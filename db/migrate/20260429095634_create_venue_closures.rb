class CreateVenueClosures < ActiveRecord::Migration[8.1]
  def change
    create_table :venue_closures do |t|
      t.references :venue, null: false, foreign_key: true

      t.string :title, null: false
      t.text :description

      t.datetime :start_time, null: false
      t.datetime :end_time, null: false

      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    # Indexes
    add_index :venue_closures, [ :venue_id, :start_time, :end_time ]
    add_index :venue_closures, [ :venue_id, :start_time ]
    add_index :venue_closures, [ :start_time, :end_time ]

    # Check constraint
    add_check_constraint :venue_closures,
      'end_time > start_time',
      name: 'closure_end_after_start'
  end
end
