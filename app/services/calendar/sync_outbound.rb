module Calendar
  class SyncOutbound < ApplicationService
    def initialize(task, action: :upsert)
      @task = task
      @action = action
    end

    def call
      token = CalendarToken.first
      return Result.new(success: false, errors: ["No calendar token"]) unless token
      return Result.new(success: true, data: { skipped: true }) unless @task.due_date

      if token.expired?
        refresh = Calendar::RefreshToken.call
        return refresh unless refresh.success?
        token.reload
      end

      service = build_service(token)

      case @action
      when :upsert then upsert_event(service)
      when :delete then delete_event(service)
      end

      Result.new(success: true, data: { event_id: @task.google_event_id })
    rescue => e
      Result.new(success: false, errors: ["Calendar sync failed: #{e.message}"])
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

    def upsert_event(service)
      event = Google::Apis::CalendarV3::Event.new(
        summary: @task.title,
        description: @task.description,
        start: { date_time: @task.due_date.to_datetime.rfc3339 },
        end: { date_time: (@task.due_date + 1.hour).to_datetime.rfc3339 }
      )

      # Update event or create new one
      if @task.google_event_id.present?
        result = service.update_event("primary", @task.google_event_id, event)
      else
        result = service.insert_event("primary", event)
        @task.update_column(:google_event_id, result.id)
      end
    end

    def delete_event(service)
      return unless @task.google_event_id
      service.delete_event("primary", @task.google_event_id)
      @task.update_column(:google_event_id, nil)
    rescue Google::Apis::ClientError
      # Event already deleted
      @task.update_column(:google_event_id, nil)
    end
  end
end
