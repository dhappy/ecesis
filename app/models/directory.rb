class Directory < ApplicationRecord
  has_many :shares, dependent: :destroy
end
