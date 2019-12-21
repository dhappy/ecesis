class Author < ApplicationRecord
  has_many :books
  has_many :titles, through: :books

  def to_s; name; end
end
