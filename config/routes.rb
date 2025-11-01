Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # auth_token
      resources :auth_token, only: [:create] do
        post :refresh, on: :collection
        delete :destroy, on: :collection
      end

      #projects
      resources :projects, only: [:index]
      # meals（←ここを拡張）
      resources :meals, only: [:index, :create, :update, :destroy, :show] do
        collection do
          get :summary   # /api/v1/meals/summary
          get :calendar  # /api/v1/meals/calendar
        end
      end
      # foods
      resources :foods, only: [:index]

      #users
      get 'me', to: 'users#me'
      put 'users/goals', to: 'users#update_goals'

      resources :users, only: [:create]
    end
  end
end
