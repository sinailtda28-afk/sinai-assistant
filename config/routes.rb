# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Home
  root "tasks#index"

  # Tasks
  resources :tasks, only: [ :index, :show, :create, :update, :destroy ] do
    member { post :move }
    resources :comments, only: [ :create ]
  end

  # Columns
  resources :columns, only: [ :create, :update, :destroy ]

  # History
  get "history" => "history#index"

  # Calendar
  get "calendar" => "calendar#index", as: :calendar
  get "calendar/day" => "calendar#day", as: :calendar_day

  # Tags
  get "tags" => "tags#index"
  post "tags" => "tags#create"
  delete "tags/:id" => "tags#destroy", as: :tag

  # Settings / AI Context
  get "settings" => "settings#index"
  post "settings" => "settings#update"

  # AI Chat
  post "chat/ask" => "chat#ask"
  post "chat/analyze" => "chat#analyze"

  # WhatsApp
  post "whatsapp/send" => "whatsapp#send_message"
  post "whatsapp/generate_message" => "whatsapp#generate_message"
  get "whatsapp/instances" => "whatsapp#instances"
  get "whatsapp/qrcode" => "whatsapp#qrcode"
  post "whatsapp/reconnect" => "whatsapp#reconnect"

  # Subtasks
  resources :subtasks, only: [ :create, :update ]

  # Dashboard
  get "dashboard" => "dashboard#index", as: :dashboard

  # Telegram
  namespace :telegram do
    post "webhook", to: "webhooks#receive"
  end
end
