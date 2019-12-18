class Share < ApplicationRecord
  belongs_to :server
  belongs_to :directory
  belongs_to :data, class_name: 'Datum'

  def irc_link
    "!#{server.name} #{data.name}"
  end

  def self.parse(file)
    shares = []
    first_seen = false
    dir = nil

    file.each do |line|
      if line.strip! =~ /^=+$/
        first_seen = true
        next
      end
      next unless first_seen
      if line.strip.empty?
        dir = nil
        next
      end
      if dir.nil?
        dir = Directory.find_or_create_by(
          name: line
        )
        next
      end
      line =~ /!([^ ]+) (.+?) * ::INFO:: (.+)$/
      server = Server.find_or_create_by(
        name: $1
      )
      data = Datum.find_or_create_by(
        name: $2, size: $3
      )
      shares << Share.find_or_create_by(
        server: server,
        directory: dir,
        data: data
      )
    end

    shares
  end
end
