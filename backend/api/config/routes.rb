# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.development?
    mount Scalar::UI, at: "/api-docs"
  end

  namespace :api do
    namespace :v1 do
      get  "me",                to: "me#show"
      put  "me/profile",        to: "profile#update"
      put  "me/health_summary", to: "health_summary#update"

      namespace :auth do
        post "register", to: "registrations#create"
        post "login",    to: "sessions#create"
        post "refresh",  to: "tokens#create"
        post "guest",   to: "guest_registrations#create"
      end

      resources :spark_sessions, only: [ :create ] do
        member do
          post :join
          post :submit_answers
          get  :result
        end
      end

      resources :spark_rewards, only: [ :index ]

      resources :matches, only: [ :index ] do
        collection do
          post :simulate
        end
      end
    end
  end
end
