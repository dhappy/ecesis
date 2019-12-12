class Book < ApplicationRecord
  belongs_to :author
  belongs_to :title

  def to_s
    "#{author.name} - #{title.name}"
  end
end
