class CreatePricingRules < ActiveRecord::Migration[7.1]
  def change
    create_table :pricing_rules do |t|
      t.references :venue, null: false, foreign_key: true
      t.references :court, null: false, foreign_key: true

      t.string :name, null: false
      t.decimal :price_per_hour, precision: 10, scale: 2, null: false

      # Time-based rules
      t.integer :day_of_week, null: false, default: 7 # 0 = Monday, 6 = Sunday, 7 = all days, 8 = weekdays, 9 = weekends
      t.time :start_time
      t.time :end_time

      # Date-based rules (nullable for permanent rules)
      t.date :start_date
      t.date :end_date

      # Priority and status
      t.integer :priority, default: 0, null: false
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end

    # Indexes
    add_index :pricing_rules, [ :venue_id, :court_id ]
    add_index :pricing_rules, :is_active
    add_index :pricing_rules, :priority

    # Check constraints
    add_check_constraint :pricing_rules,
      'price_per_hour >= 0',
      name: 'price_non_negative'
  end
end
