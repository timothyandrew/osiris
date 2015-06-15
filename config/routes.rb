Rails.application.routes.draw do
  get '/files', to: "files#index"
  get '/files/*path', to: "files#index"
end
