class CreatePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :permissions do |t|
      t.string :resource, null: false
      t.string :action, null: false

      t.timestamps
    end

    add_index :permissions, [ :resource, :action ], unique: true
    add_index :permissions, :resource
  end
end
