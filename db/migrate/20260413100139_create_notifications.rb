class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :venue, null: true, foreign_key: true
      t.references :booking, null: true, foreign_key: true

      t.string :notification_type, null: false
      t.string :title, null: false
      t.text :message, null: false
      t.string :action_url

      t.boolean :is_read, default: false, null: false
      t.datetime :read_at
      t.string :priority, default: 'normal', null: false
      t.datetime :sent_at

      t.timestamps
    end

    # Indexes
    add_index :notifications, [ :user_id, :is_read ]
    add_index :notifications, [ :user_id, :created_at ]
    add_index :notifications, :notification_type
    add_index :notifications, :priority
  end
end
