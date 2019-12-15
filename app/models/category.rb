class Category < ApplicationRecord
  has_many :entries
  has_many :nominees, through: :entries, class_name: 'Book'
end
