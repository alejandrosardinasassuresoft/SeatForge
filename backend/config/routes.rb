Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"

      resources :workshops, only: [:index, :create, :show] do
        resources :sessions, only: [:create]
      end

      resources :sessions, only: [:index, :show] do
        resources :registrations, only: [:create]
      end

      resources :registrations, only: [] do
        member do
          post :confirm
          post :cancel
        end
      end

      resources :attendees, only: [] do
        member do
          get :registrations
        end
      end

      get "dashboard", to: "dashboard#show"
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end