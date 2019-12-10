namespace :import do
  desc 'Import data from external sources'

  task(
    :json,
    [:file, :award] => [:environment]
  ) do |t, args|
    award = Award.find_or_create_by(
      name: args[:award]
    )
    data = File.open(args[:file]) do |f|
      JSON.parse(f.read)
    end
    data.each do |year, data|
      yr = Year.find_or_create_by(number: year.to_i)
      award.years << yr
      data.each do |cat, data|
        category = Category.find_or_create_by(
          name: cat
        )
        yr.categories << category
        data.each do |nominee|
          next unless nominee.has_key?(:author)
          author = Author.find_or_create_by(name: nominee[:author])
          title = Title.find_or_create_by(name: nominee[:title])
          author.titles << title
          category.entries << Book.find_or_create_by(
            author: author, title: title
          )
        end
      end
    end
    byebug
  end
end