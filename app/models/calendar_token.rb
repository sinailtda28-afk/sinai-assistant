class CalendarToken < ApplicationRecord
  def expired?
    expires_at.nil? || expires_at < Time.current
  end

  def refresh!
    return unless refresh_token

    client = Signet::OAuth2::Client.new(
      client_id: Rails.application.credentials.dig(:google, :client_id),
      client_secret: Rails.application.credentials.dig(:google, :client_secret),
      refresh_token: refresh_token
    )

    client.refresh!
    update!(
      access_token: client.access_token,
      expires_at: Time.current + client.expires_in.to_i.seconds
    )
  end
end
