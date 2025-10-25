Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # （auth_token）
      resources :auth_token, only: [:create] do
        post :refresh, on: :collection # アクセストークン再発行
        delete :destroy, on: :collection # ログアウト
      end

      # meals
      resources :meals, only: [:index, :create, :update, :destroy, :show] do
        collection do
          get :summary   # 期間合計・栄養サマリなどの集計用
          get :calendar
        end
      end

      # foods
      resources :foods, only: [:index]

      # users
      get 'me', to: 'users#me' # 現在のユーザー情報取得
      put 'users/goals', to: 'users#update_goals' # ユーザーの栄養目標値更新

      resources :users, only: [:create] # ユーザー登録
    end
  end
end
