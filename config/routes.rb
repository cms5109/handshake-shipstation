Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/shipstation', to: 'shipstation#index'
  post '/shipstation', to: 'shipstation#shipnotify'
end
