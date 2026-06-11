class CreateCalendarTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :calendar_tokens do |t|
      t.string :access_token
      t.string :refresh_token
      t.datetime :expires_at
      t.string :google_sync_token
      t.timestamps
    end
  end
end
