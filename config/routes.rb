Rails.application.routes.draw do
  root to: "files#index"
  get '/files', to: "files#index"
  get '/files/*path', to: "files#index"
end
