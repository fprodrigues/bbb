Rails.application.routes.draw do
  get "/health", to: proc { [200, { "Content-Type" => "application/json" }, ['{"status":"ok"}']] }
  get "/metrics", to: "metrics#index"

  namespace :api do
    resources :participants, only: [:index]

    get "/elections/current", to: "elections#current"
    get "/elections/current/results", to: "elections#results"
    get "/elections/current/hourly", to: "elections#hourly"

    resources :votes, only: [:create]

    namespace :admin do
      resources :elections, only: [:create] do
        member do
          post :start
          post :close
        end

        collection do
          get :history
        end
      end
    end
  end
end