Rails.application.routes.draw do

  root 'searches#new'
  get 'searches/new'
  post 'searches/create'
  get 'searches/index'
  get 'searches/download_xls'
  get 'searches/download_images'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
