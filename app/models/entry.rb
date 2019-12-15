class Entry < ApplicationRecord
  belongs_to :award
  belongs_to :category
  belongs_to :year
  belongs_to :nominee, class_name: 'Book'

  def to_s
    nominee&.to_s
  end
end
