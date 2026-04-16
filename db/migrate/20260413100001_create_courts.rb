class CreateCourts < ActiveRecord::Migration[8.1]
  def change
    create_table :courts do |t|
      t.references :venue, null: false, foreign_key: true
      t.references :court_type, null: false, foreign_key: true

      t.string :name, null: false
      t.text :description
      t.boolean :is_active, default: true, null: false
      t.integer :display_order, default: 0, null: false

      # Images (Shrine storage)
      t.jsonb :images_data # Array of Shrine image objects

      # QR code for check-in
      t.string :qr_code_url # URL of generated QR PNG on S3

      t.timestamps
    end

    # Indexes
    add_index :courts, [ :venue_id, :name ], unique: true
    add_index :courts, :is_active
  end
end
