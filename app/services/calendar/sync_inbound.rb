module Calendar
  class SyncInbound < ApplicationService
    def call
      token = CalendarToken.first
      return Result.new(success: false, errors: ["No calendar token"]) unless token

      service = build_service(token)
      page_token = token.google_sync_token

      response = service.list_events("primary", sync_token: page_token, page_token: page_token)

      if response.next_sync_token
        token.update!(google_sync_token: response.next_sync_token)
      end

      Result.new(success: true, data: { synced: response.items&.size || 0 })
    rescue Google::Apis::ClientError => e
      # Sync token expired - do full sync
      if e.message.include?("sync token")
        token.update!(google_sync_token: nil)
        Result.new(success: true, data: { note: "Sync token reset - full sync on next run" })
      else
        Result.new(success: false, errors: [e.message])
      end
    end

    private

    def build_service(token)
      Google::Apis::CalendarV3::CalendarService.new.tap do |s|
        s.authorization = Google::Auth::UserRefreshCredentials.new(
          client_id: Rails.application.credentials.dig(:google, :client_id),
          client_secret: Rails.application.credentials.dig(:google, :client_secret),
          refresh_token: token.refresh_token
        )
      end
    end
  end
end
