class Datum < ApplicationRecord
  has_many :shares, foreign_key: :data_id, dependent: :nullify
  has_many :contents, foreign_key: :data_id, dependent: :destroy
  has_many :books, through: :contents

  def url
    "http://ipfs.io/ipfs/#{ipfs_id}"
  end
end
