# frozen_string_literal: true

# Configure SQLite database path for production.
# Uses DATABASE_PATH env var for persistent storage on Railway/Render.
# Falls back to local path when env var is not set.
#
# Required for Railway/Render: mount a volume and set DATABASE_PATH
# to the volume path (e.g., /data/db/production.sqlite3).

unless Rails.env.production?
  return
end

path = ENV.fetch("DATABASE_PATH", nil)
return unless path

# Ensure the directory exists
dir = File.dirname(path)
FileUtils.mkdir_p(dir) unless File.directory?(dir)

Rails.logger.info("Production database path: #{path}")
