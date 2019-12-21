class Filename < ApplicationRecord
  has_many :shares
  has_many :links

  def extension
    name.sub(/^.*\./, '').downcase
  end

  def possible_books
    @names ||= [].tap do |names|
      if name =~ /^(.*?) +by +(.*)\.(.*?)$/
        names.push({
          author: $2, title: $1
        })
      end
      if name =~ /^(.*?) +- +(.*)\.(.*?)$/
        names.push({
          author: $1, title: $2
        })
      end
    end
  end

  def mimetype
    case extension
    when 'epub'; 'application/epub+zip'
    when 'html', 'xhtml'; 'text/html'
    when 'pdf'; 'application/pdf'
    when 'rar'; 'application/x-rar-compressed'
    else; 'unknown/unknown'
    end
  end

  def to_s; name; end
end
