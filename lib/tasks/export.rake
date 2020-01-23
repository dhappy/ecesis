namespace :export do
  desc 'Export data to external sources'

  task(dirs: :environment) do |t|
    paths = []

    endpoints = Content.all.includes(:book).map(&:book)
    pattern = [:book, :by, '#{author}', '#{title}']
    endpoints.each do |book|
      data = {
        author: book.author,
        title: book.title,
      }
      path = pattern.map do |pat|
        pat.to_s.gsub(/\#\{(\w+)\}/) { data[$1.to_sym].to_s }
      end
      paths.push({
        path: path,
        ipfs_id: book.data.first&.ipfs_id
      })
    end

    endpoints = Award.all
    patterns = [
      [:award, '#{award}', '#{year}', '#{author} - #{title}'],
      [:award, '#{award}', '#{year}', '#{category}', '#{author} - #{title}'],
      [:award, '#{award}', '#{category}', '#{author} - #{title}'],
      [:award, '#{award}', '#{category}', '#{year}', '#{author} - #{title}'],
      [:book, :by, '#{author}', '#{title}']
    ]
    endpoints.each do |award|
      award.years.each do |year|
        year.categories.where(
          name: ['Best Novel', 'Best Novella', 'Best Short Story']
        ).each do |cat|
          Entry.where(
            award: award,
            year: year,
            category: cat
          )
          .includes(:nominee)
          .map(&:nominee)
          .each do |book|
            data = {
              award: award,
              year: year,
              category: cat,
              author: book.author,
              title: book.title,
            }
            patterns.each do |pattern|
              path = pattern.map do |pat|
                pat.to_s.gsub(/\#\{(\w+)\}/) { data[$1.to_sym].to_s }
              end
              paths.push({
                path: path,
                ipfs_id: book.data.first&.ipfs_id
              })
            end
          end
        end
      end
    end

    puts paths.to_json
  end

  task(gutenberg: :environment) do |t|
    Datum.where('gutenberg_id IS NOT NULL').each do |data|
      data.books.each do |book|
        gdir = data.gutenberg_id.split('')[0..-2] + [data.gutenberg_id]
        if book.author
          path = %W[tmp book by #{book.author.to_s}]
          byebug
          FileUtils.makedirs(File.join(path))
          FileUtils.symlink(
            File.join(pat h + [  book.title.to_s]),
            File.join(['...', :gutenberg] + gdir)
          )
        end
        puts data.url
      end
    end
  end
end