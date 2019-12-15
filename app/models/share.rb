class Share < ApplicationRecord
  belongs_to :server
  belongs_to :directory

  def self.parse(file)
    shares = []
    first_seen = false

    file.each do |line|
      first_seen = true if line =~ /^=+$/
      next unless first_seen
      if line.empty
        dir = nil
        next
      end
      if !defined?(dir) || dir.nil?
        dir = Directory.find_or_create_by(
          name: line
        )
        next
      end
      line =~ /!(.+) (.+)  ::INFO:: (.+)$/
      server = Server.find_or_create_by(
        name: $1
      )
      filename = Filename.find_or_create_by(
        name: $2
      )
      shares << Share.find_or_create_by(
        server: server,
        directory: directory,
        filename: filename,
        size: $3
      )
    end

    shares
  end
end
