class Datum < ApplicationRecord
  has_many :shares, foreign_key: :data_id, dependent: :nullify

  def url
    "http://ipfs.io/ipfs/#{ipfs_id}"
  end
end
