Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      namespace :signals do
        post :preferences, to: 'signals/preferences#create'
      end
    end
  end
end
