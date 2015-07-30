Rails.application.routes.draw do
  devise_for :users
  root to: "files#index"
  get '/files', to: "files#index"
  get '/files/*path', to: "files#index"
end
