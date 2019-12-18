class Year < ApplicationRecord
  has_many :entries
  has_many(
    :categories,
    -> { distinct },
    through: :entries
  )
end
