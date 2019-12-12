class Category < ApplicationRecord
  has_and_belongs_to_many :entries, class_name: 'Book'
end
