class Datum < ApplicationRecord
  has_many :shares, foreign_key: :data_id
end
