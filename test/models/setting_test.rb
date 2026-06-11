require "test_helper"

class SettingTest < ActiveSupport::TestCase
  test "valid with key" do
    setting = Setting.new(key: "telegram_chat_id", value: "12345")
    assert setting.valid?
  end

  test "invalid without key" do
    setting = Setting.new(value: "test")
    assert_not setting.valid?
    assert_includes setting.errors[:key], "can't be blank"
  end

  test "key is unique" do
    Setting.create!(key: "unique_key", value: "v1")
    duplicate = Setting.new(key: "unique_key", value: "v2")
    assert_not duplicate.valid?
  end

  test ".get returns value for existing key" do
    Setting.create!(key: "my_setting", value: "hello")
    assert_equal "hello", Setting.get("my_setting")
  end

  test ".get returns default for missing key" do
    assert_equal "default_val", Setting.get("nonexistent", "default_val")
  end

  test ".get returns nil without default for missing key" do
    assert_nil Setting.get("nonexistent")
  end

  test ".set creates new setting" do
    setting = Setting.set("new_key", "new_value")
    assert_equal "new_value", setting.value
    assert_equal "new_value", Setting.get("new_key")
  end

  test ".set updates existing setting" do
    Setting.create!(key: "existing", value: "old")
    Setting.set("existing", "updated")
    assert_equal "updated", Setting.get("existing")
  end
end
