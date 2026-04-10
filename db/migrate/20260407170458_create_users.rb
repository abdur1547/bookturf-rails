class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      # Authentication
      t.string :email, null: false
      t.string :password_digest, null: false

      # Personal Information
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :phone_number

      # Emergency Contact
      t.string :emergency_contact_name
      t.string :emergency_contact_phone

      # OAuth fields
      t.string :provider
      t.string :uid
      t.string :avatar_url

      # Status
      t.boolean :is_active, default: true, null: false
      t.boolean :is_global_admin, default: false, null: false

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :phone_number
    add_index :users, [ :provider, :uid ], unique: true
    add_index :users, :is_active
    add_index :users, :is_global_admin
  end
end
