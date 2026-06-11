class CreateConversationStates < ActiveRecord::Migration[8.1]
  def change
    create_table :conversation_states do |t|
      t.integer :chat_id, null: false
      t.string :state, null: false, default: "idle"
      t.string :pending_intent
      t.text :pending_data
      t.datetime :expires_at

      t.timestamps
    end

    add_index :conversation_states, :chat_id, unique: true
  end
end
