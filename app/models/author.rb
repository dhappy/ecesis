class Author < ApplicationRecord
  has_many :books
  has_many :titles, through: :books
end
