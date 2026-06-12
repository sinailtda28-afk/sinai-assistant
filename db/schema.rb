# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_11_214512) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "calendar_tokens", id: :integer, default: nil, force: :cascade do |t|
    t.text "access_token"
    t.text "created_at"
    t.text "expires_at"
    t.text "google_sync_token"
    t.text "refresh_token"
    t.text "updated_at"
  end

  create_table "columns", force: :cascade do |t|
    t.string "color", default: "#6b7280"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "task_id", null: false
    t.datetime "updated_at", null: false
    t.index ["task_id"], name: "index_comments_on_task_id"
  end

  create_table "conversation_states", force: :cascade do |t|
    t.integer "chat_id", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.text "pending_data"
    t.string "pending_intent"
    t.string "state", default: "idle", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_conversation_states_on_chat_id", unique: true
  end

  create_table "notification_settings", id: :integer, default: nil, force: :cascade do |t|
    t.text "channel", null: false
    t.text "created_at"
    t.integer "daily_summary", default: 1
    t.integer "overdue_alert", default: 1
    t.text "quiet_end"
    t.text "quiet_start"
    t.integer "reminder_minutes", default: 30
    t.text "updated_at"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "subtasks", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "position", default: 0
    t.integer "task_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["task_id"], name: "index_subtasks_on_task_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "task_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "tag_id", null: false
    t.integer "task_id", null: false
    t.datetime "updated_at", null: false
    t.index ["task_id", "tag_id"], name: "index_task_tags_on_task_id_and_tag_id", unique: true
  end

  create_table "tasks", force: :cascade do |t|
    t.integer "column_id", null: false
    t.datetime "completed_at"
    t.integer "completed_count", default: 0
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "due_date"
    t.boolean "is_recurring", default: false
    t.string "link"
    t.integer "parent_task_id"
    t.integer "position", default: 0
    t.integer "priority", default: 1
    t.integer "recurrence_day"
    t.string "recurrence_type"
    t.string "recurring_interval"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["column_id"], name: "index_tasks_on_column_id"
    t.index ["completed_at"], name: "index_tasks_on_completed_at"
    t.index ["due_date"], name: "index_tasks_on_due_date"
    t.index ["parent_task_id"], name: "index_tasks_on_parent_task_id"
    t.index ["priority"], name: "index_tasks_on_priority"
  end

  create_table "telegram_messages", force: :cascade do |t|
    t.integer "chat_id", null: false
    t.float "confidence"
    t.datetime "created_at", null: false
    t.string "intent"
    t.text "raw_payload"
    t.string "status", default: "received", null: false
    t.text "text"
    t.integer "update_id", null: false
    t.datetime "updated_at", null: false
    t.string "voice_file_id"
    t.index ["chat_id"], name: "index_telegram_messages_on_chat_id"
    t.index ["status"], name: "index_telegram_messages_on_status"
    t.index ["update_id"], name: "index_telegram_messages_on_update_id", unique: true
  end

  create_table "whatsapp_instances", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.string "name"
    t.string "number"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comments", "tasks"
  add_foreign_key "subtasks", "tasks"
  add_foreign_key "task_tags", "tags"
  add_foreign_key "task_tags", "tasks"
  add_foreign_key "tasks", "columns"
end
