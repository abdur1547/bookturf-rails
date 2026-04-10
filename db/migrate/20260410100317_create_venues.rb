class CreateVenues < ActiveRecord::Migration[8.1]
  def change
    create_table :venues do |t|
      # Ownership
      t.references :owner, null: false, foreign_key: { to_table: :users }

      # Identity
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description

      # Location
      t.text :address, null: false
      t.string :city
      t.string :state
      t.string :country
      t.string :postal_code
      t.decimal :latitude, precision: 10, scale: 8
      t.decimal :longitude, precision: 11, scale: 8

      # Contact
      t.string :phone_number
      t.string :email

      # Status
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end

    # Indexes (owner_id already indexed by t.references)
    add_index :venues, :slug, unique: true
    add_index :venues, :city
    add_index :venues, :state
    add_index :venues, :country
    add_index :venues, :is_active
  end
end
