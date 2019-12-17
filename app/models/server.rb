class Server < ApplicationRecord
  has_many :shares
  has_many :directories, through: :shares
end
