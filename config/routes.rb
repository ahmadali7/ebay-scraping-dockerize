Rails.application.routes.draw do

  root 'searches#new'
  get 'searches/new'
  post 'searches/create'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
