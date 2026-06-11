class CreateTelegramMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :telegram_messages do |t|
      t.integer :update_id, null: false
      t.integer :chat_id, null: false
      t.text :text
      t.string :voice_file_id
      t.string :status, default: "received", null: false
      t.string :intent
      t.float :confidence
      t.text :raw_payload

      t.timestamps
    end

    add_index :telegram_messages, :update_id, unique: true
    add_index :telegram_messages, :status
    add_index :telegram_messages, :chat_id
  end
end
