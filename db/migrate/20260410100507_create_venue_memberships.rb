class CreateVenueMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :venue_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :venue, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true

      t.timestamps
    end

    add_index :venue_memberships, [ :user_id, :venue_id ], unique: true
  end
end
