# frozen_string_literal: true

# Configure SQLite3 adapter for production use
# - WAL mode for concurrent reads
# - busy_timeout to retry instead of error on write locks
# - foreign_keys enforced
# - cache_size and mmap_size for performance

return unless defined?(ActiveRecord::ConnectionAdapters::SQLite3Adapter)

ActiveRecord::ConnectionAdapters::SQLite3Adapter.class_eval do
  alias_method :original_configure_connection, :configure_connection

  def configure_connection
    original_configure_connection
    execute("PRAGMA journal_mode=WAL;")
    execute("PRAGMA busy_timeout=5000;")
    execute("PRAGMA foreign_keys=ON;")
    execute("PRAGMA cache_size=-64000;")
    execute("PRAGMA mmap_size=268435456;")
  end
end
