ActivePrompt::Engine.routes.draw do
  root to: "prompts#index"
  
  resources :prompts do
    member do
      post :test
      post :duplicate
    end
    collection do
      get :search
    end
  end
  
  resources :templates do
    member do
      post :preview
    end
  end
  
  resources :responses, only: [:index, :show, :destroy]
  
  # API endpoints for integration
  namespace :api do
    namespace :v1 do
      resources :prompts, only: [:index, :show] do
        member do
          post :execute
        end
      end
    end
  end
end
