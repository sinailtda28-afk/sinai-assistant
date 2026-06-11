ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
require "vcr"
require "webmock/minitest"

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data("<TELEGRAM_TOKEN>") { ENV.fetch("TELEGRAM_BOT_TOKEN", "test_token") }
  config.filter_sensitive_data("<OPENAI_KEY>") { ENV.fetch("OPENAI_API_KEY", "test_key") }
  config.filter_sensitive_data("<GOOGLE_CLIENT_ID>") { ENV.fetch("GOOGLE_CLIENT_ID", "test_client_id") }
  config.filter_sensitive_data("<GOOGLE_CLIENT_SECRET>") { ENV.fetch("GOOGLE_CLIENT_SECRET", "test_secret") }
end

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    fixtures :all

    def after_teardown
      super
      VCR.eject_cassette if VCR.current_cassette
    rescue VCR::Errors::NotAllowedError
      # no active cassette
    end
  end
end
