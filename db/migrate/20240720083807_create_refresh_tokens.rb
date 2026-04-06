class CreateRefreshTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :refresh_tokens do |t|
      t.string :crypted_token
      t.belongs_to :user, null: false, foreign_key: true
      t.datetime :exp, null: false, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end
    add_index :refresh_tokens, :crypted_token, unique: true
  end
end
