# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Home
  root "tasks#index"

  # Tasks
  resources :tasks, only: [ :index, :create, :update, :destroy ] do
    member { post :move }
  end

  # Columns
  resources :columns, only: [ :update ]

  # History
  get "history" => "history#index"

  # Calendar
  get "calendar" => "calendar#index", as: :calendar
  get "calendar/day" => "calendar#day", as: :calendar_day

  # Subtasks
  resources :subtasks, only: [ :create, :update ]

  # Dashboard
  get "dashboard" => "dashboard#index", as: :dashboard

  # Telegram
  namespace :telegram do
    post "webhook", to: "webhooks#receive"
  end
end
