class CreatePasswordResetTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :password_reset_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :otp_code_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at

      t.timestamps
    end

    add_index :password_reset_tokens, :otp_code_digest
    add_index :password_reset_tokens, :expires_at
  end
end
