class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles do |t|
      t.references :venue, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end

    add_index :roles, [ :venue_id, :name ], unique: true
  end
end
