class Entry < ApplicationRecord
  belongs_to :award
  belongs_to :category
  belongs_to :year
  belongs_to :nominee
end
