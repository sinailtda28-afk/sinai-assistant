class SettingsController < ApplicationController
  def index
    @settings = {}
    Setting.all.each { |s| @settings[s.key] = s.value }
  end

  def update
    params[:settings]&.each do |key, value|
      setting = Setting.find_or_initialize_by(key: key)
      setting.update!(value: value)
    end
    redirect_to root_path, notice: "Configuracoes salvas"
  rescue => e
    redirect_to root_path, alert: e.message
  end
end
