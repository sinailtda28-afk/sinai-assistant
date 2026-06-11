class CreateNotificationSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_settings do |t|
      t.string :channel, null: false
      t.integer :reminder_minutes, default: 30
      t.boolean :daily_summary, default: true
      t.string :quiet_start
      t.string :quiet_end
      t.boolean :overdue_alert, default: true
      t.timestamps
    end
  end
end
