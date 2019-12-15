Rails.application.routes.draw do
  resources :shares
  resources :servers
  resources :filenames
  resources :directories
  resources :source_strings
  resources :entries
  root 'awards#index'

  resources :books_categories
  resources :books
  resources :titles
  resources :categories
  resources :years
  resources :awards
  resources :authors
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
