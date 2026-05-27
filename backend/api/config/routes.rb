# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.development?
    mount Scalar::UI, at: "/api-docs"
  end

  namespace :api do
    namespace :v1 do
      get "me", to: "me#show"
      put "me/profile", to: "profile#update"

      namespace :auth do
        post "register", to: "registrations#create"
        post "login",    to: "sessions#create"
        post "refresh",  to: "tokens#create"
      end
    end
  end
end
