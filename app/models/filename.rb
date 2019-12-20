class Filename < ApplicationRecord
  has_many :shares

  def to_s
    name
  end
end
