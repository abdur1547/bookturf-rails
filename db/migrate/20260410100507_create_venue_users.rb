class CreateVenueUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :venue_users do |t|
      t.references :venue, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      # Track who added this staff member and when
      t.references :added_by, foreign_key: { to_table: :users }
      t.datetime :joined_at, null: false

      t.timestamps
    end

    # Ensure a user can only be added to a venue once
    add_index :venue_users, [ :venue_id, :user_id ], unique: true
  end
end
