class Book < ApplicationRecord
  belongs_to :author
  belongs_to :title
  has_many :contents
  has_many :data, through: :contents
  has_many :entries, foreign_key: :nominee_id
  has_many :links, dependent: :destroy

  def self.for(author, title)
    author = Author.find_or_create_by(name: author)
    title = Title.find_or_create_by(name: title)
    find_or_create_by(author: author, title: title)
  end

  def possible_filenames
    @fnames ||= Filename.where(
      'name ILIKE ?', "%#{author}%#{title}%"
    )
    .or(Filename.where(
      'name ILIKE ?', "%#{title}%#{author}%"
    ))
  end

  def found?
    puts "Checking: #{Rails.root}/public/book/by/#{author}/#{title}/html"
    Dir.glob("#{Rails.root}/public/book/by/#{author}/#{title}/*html").length > 0
  end

  def to_s
    "#{author.name} - #{title.name}"
  end
end
