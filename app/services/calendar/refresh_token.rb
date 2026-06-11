module Calendar
  class RefreshToken < ApplicationService
    def call
      token = CalendarToken.first
      return Result.new(success: false, errors: ["No token configured"]) unless token

      token.refresh!
      Result.new(success: true, data: token)
    rescue => e
      Result.new(success: false, errors: ["Token refresh failed: #{e.message}"])
    end
  end
end
