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
    data.each do |yr, data|
      year = Year.find_or_create_by(number: yr.to_i)
      data.each do |cat, data|
        category = Category.find_or_create_by(
          name: cat
        )

        data.each do |nominee|
          book = (
            Book.for(
              nominee['author'], nominee['title']
            )
          )
          source = SourceString.find_or_create_by(
            text: nominee['raw']
          )
          Entry.find_or_create_by(
            award: award,
            year: year,
            category: category,
            won: nominee['won'],
            nominee: book
          )
        end
      end
    end
  end
end