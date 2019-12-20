class Link < ApplicationRecord
  belongs_to :book
  belongs_to :filename
end
