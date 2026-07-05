# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      namespace :signals do
        post :preferences, to: 'preferences#create'
      end
    end
  end
end
