Rails.application.routes.draw do
  resources :data
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

  get '/import' => 'pages#import'
end
