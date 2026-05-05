class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false

      t.string :full_name, null: false
      t.string :phone_number

      t.string :emergency_contact_name
      t.string :emergency_contact_phone

      t.string :provider
      t.string :uid
      t.string :avatar_url

      t.boolean :is_active, default: true, null: false
      t.integer :system_role, default: 0, null: false

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :phone_number, unique: true
    add_index :users, [ :provider, :uid ], unique: true
    add_index :users, :is_active
    add_index :users, :system_role
  end
end
