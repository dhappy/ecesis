namespace :import do
  desc 'Import data from external sources'

  BANNED = ['bsk']

  task(
    :gutencache,
    [:dir] => [:environment]
  ) do |t, args|
    puts "Searching: #{args[:dir]}/*/*-images.epub"
    outdir = "gutenlinks-#{Time.now.iso8601}"
    puts " For: #{outdir}"

    Dir.glob("#{args[:dir]}/*").each.with_index do |dir, idx|
      next unless File.directory?(dir)
      ls = Dir.glob("#{dir}/*-images.epub")
      ls = Dir.glob("#{dir}/*.epub") if ls.empty?
      epub = ls.first
      guten_id = dir.match(/(\d+)$/).try(:[], 1)

      unless epub && guten_id
        $stderr.puts "Error: No epub (#{guten_id}) in #{dir}"
        next
      end

      puts "Importing: #{epub} (#{idx})"
      path = Pathname.new(epub)
      FileUtils.chdir(File.dirname(epub))
    
      if File.directory?('html')
        puts ' Found HTML Directory: Skipping Generation'
      else
        begin
          epub = File.basename(epub)
          htmlz = "#{File.basename(epub, '.*')}.htmlz"

          print ' First, generate htmlz:'
          unless system('ebook-convert', epub, htmlz)
            raise RuntimeError, "Converting #{guten_id}"
          end
          puts ' Done'

          FileUtils.makedirs('html')

          print ' Next, unzip it:'
          unless system('unzip', '-qod', 'html/', htmlz)
            raise RuntimeError, "Unzipping #{guten_id}"
          end
          puts ' Done'

          print ' Next, copy complete metadata:'
          metadata = Dir.glob('*.rdf').try(:[], 0)
          unless metadata
            raise RuntimeError, "No Metadata for #{guten_id}"
          end
          FileUtils.copy(metadata, 'html/metadata.rdf')
          puts ' Done'

          print ' Then, fix links:'
          unless system(
            'xsltproc', '--html', '-o', 'html/index.html',
            Rails.root.join('bin', 'relativize_paths.xslt').to_s,
            'html/index.html'
          )
            raise RuntimeError, "Cleaning HTML: #{guten_id}"
          end
          puts ' Done'
        rescue RuntimeError => err
          puts "Error: #{err.message}"
          FileUtils.rmtree('html')
          next
        end
      end

      print ' Then, import it into IPFS:'
      bookId = nil
      IO.popen(['ipfs', 'add', '-r', 'html'], 'r+') do |cmd|
        out = cmd.readlines.last
        bookId = out&.split.try(:[], 1)
        unless $?.success? && bookId
            puts "Error: IPFS Import of #{guten_id} (#{bookId})"
          next
        end
      end
      puts " Done: #{bookId}"

      puts ' Next, read the metadata:'
      File.open('html/metadata.rdf') do |file|
        doc = Nokogiri::XML(file)

        xpath = ->(path, asNodes = false) {
          res = doc.xpath(
            path,
            dc: 'http://purl.org/dc/elements/1.1/',
            opf: 'http://www.idpf.org/2007/opf',
            dcterms: 'http://purl.org/dc/terms/',
            rdf: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
            pgterms: 'http://www.gutenberg.org/2009/pgterms/'
          )
          if !asNodes && res.size == 0
            nil
          elsif !asNodes && res.size === 1
            Nokogiri::HTML.parse(res.to_s).text # uses & escapes
          else
            res
          end
        }

        add = ->(paths) {
          paths.each do |path|
            next if path.any?{ |p| p.nil? || p.empty? }
            path.map!{ |p| p.gsub('%', '%25').gsub('/', '%2F').gsub("\u0000", '%00')}
            puts " Placing @: /#{File.join(path)}"
            system('ipfs', 'files', 'mkdir', '-p', "/#{outdir}/#{File.join(path[0..-2])}")
            system('ipfs', 'files', 'cp', "/ipfs/#{bookId}", "/#{outdir}/#{File.join(path)}")
          end
        }

        bibauthors = xpath.call('//dcterms:creator//pgterms:name/text()', true)
        bibauthor = bibauthors.map(&:to_s).join(' & ')
        authors = bibauthors.map do |a|
          a.to_s.sub(/^(.+?), (.+)$/, '\2 \1')
          .gsub(/\s+\(.*?\)\s*/, ' ')
        end
        author = authors.join(' & ')
        title = xpath.call('//dcterms:title/text()').gsub(/\r?\n/, ' ')
        lang = xpath.call('//dcterms:language//rdf:value/text()')
        if lang.is_a?(Nokogiri::XML::NodeSet)
          lang = "#{lang[0..-2].map(&:to_s).join(', ')} & #{lang[-1]}"
        end
        subs = (
          xpath.call('//dcterms:subject', true).map do |sub|
            val = sub.xpath('.//rdf:value/text()')
            val = val.to_s.split(/\s+--\s+/)
            taxonomy = sub.xpath('.//dcam:memberOf/@rdf:resource').to_s
            if taxonomy == 'http://purl.org/dc/terms/LCC'
              val = ['Library of Congress', 'code'] + val
            end
            val
          end
        )
        shelves = (
          xpath.call('//pgterms:bookshelf//rdf:value/text()', true).map do |shelf|
            shelf.to_s.sub(/\s*\(Bookshelf\)/, '')
          end
        )
        fulltitle = "#{title}#{author && ", by #{author}"}"

        add.call([
          ['book', 'by', author, title],
          ['book', 'bibliographically', bibauthor, title],
          ['book', 'entitled', fulltitle],
          ['book', 'language', lang, fulltitle],
          ['project', 'Gutenberg', 'id', guten_id]
        ])
        add.call(subs.map{ |s| ['subject'] + s + [fulltitle] })
        add.call(shelves.map do |s|
          %w[project Gutenberg bookshelf] + [s, fulltitle]
        end)
      end
    end
  end

  task(
    :json,
    [:file, :award] => [:environment]
  ) do |t, args|
    Rails.logger.level = 0

    award = Award.find_or_create_by(
      name: args[:award]
    )
    data = File.open(args[:file]) do |f|
      json = JSON.parse(f.read)
      entries = Entry.parse(json, award)
    end
  end

  task(
    :omenserve,
    [:file] => [:environment]
  ) do |t, args|
    File.open(args[:file]) do |f|
      Share.parse(f)
    end
  end

  task(
    :dir,
    [:dir] => [:environment]
  ) do |t, args|
    Dir.glob("#{args[:dir]}/*").each do |dir|
      puts "Processing: #{dir}"
      name = dir.sub(/^.*\//, '')
      author = Author.find_or_create_by(
        name: name
      )
      Dir.glob("#{dir}/*").each do |subd|
        puts " Processing: #{subd}"
        name = subd.sub(/^.*\//, '')
        title = Title.find_or_create_by(
          name: name
        )
        book = Book.find_or_create_by(
          author: author, title: title
        )
        unless book.data.empty?
          puts '   Data Found: Skipping.'
          next
        end
        Dir.glob("#{subd}/*") do |ssd|
          name = ssd.sub(/^.*\//, '')
          mimetype = (
            case name
            when 'epub'; 'application/epub+zip'
            when 'html', 'xhtml'; 'text/html'
            end
          )

          unless mimetype
            puts "  Unknown Filetype: #{name}"
          else
            cmd = IO.popen(['ipfs', 'add', ssd], 'r+')
            out = cmd.readlines.first
            id = out.split[1]
            data = Datum.find_or_create_by(
              ipfs_id: id, mimetype: mimetype
            )
            book.data << data
            puts "  Found #{book} (#{mimetype}): #{id}"
          end
        end
      end
    end
  end

  task(irc: :environment) do |t, args|
    require "cinch"
    require "cinch/helpers"

    def dequeue(queue, admin, channel)
      admin.send("Dequeuing: #{queue.size}")

      while nxt = queue.shift
        if nxt.has_data?
          admin.send("Duplicate REQ: #{nxt}")
        else
          break
        end
      end

      if nxt
        share = nxt.shares.sample
        admin.send("Requesting: #{share.directory}/#{share.filename} @ #{share.server}")
        channel.send(share.irc_link)
      else
        admin.send('Queue Empty')
      end
    end

    bot = Cinch::Bot.new do
      queue = []
      admin = nil
  
      configure do |c|
        c.server   = "irc.irchighway.net"
        c.channels = ['#cinch-bots', '#ebooks']
        c.nick = 'hugobot'
      end

      on :message, 'cue' do |m|
        admin ||= m.user
        filenames = Link.joins(:filename).includes(:filename).map(&:filename).uniq

        filenames.each do |fname|
          next if fname.has_data?
          next if fname.shares.empty?

          if(
            fname.shares.size == 1 \
            && BANNED.include?(fname.shares.first.server.name)
          )
            admin.send("Skipping Banned: (#{fname.shares.first.server.name}) #{fname}")
            next
          end

          queue << fname
        end

        admin.send("Queued: #{queue.size} #{'book'.pluralize(queue.size)}")
      end

      on :message, 'ls' do |m|
        admin ||= m.user
        admin.send(queue.join("\n"))
      end

      on :message, 'lss' do |m|
        admin ||= m.user
        admin.send("Queue Size: #{queue.size}")
      end

      on :message, 'clr' do |m|
        admin ||= m.user
        queue = []
        admin.send('Cleared the Queue')
      end

      on :message, 'deq' do |m|
        admin ||= m.user
        dequeue(queue, admin, m.bot.channels[1])
      end

      on :message, 'req' do |m|
      end

      on :message, 'ping' do |m|
        admin ||= m.user
        m.reply("Ping: You are#{admin != m.user ? ' not' : ''} the admin.")
      end

      on :notice do |m|
        admin.send("#{m.user}: Notice: #{m.message}")
      end

      on :dcc_send do |m, dcc|
        if dcc.from_private_ip? || dcc.from_localhost?
          m.bot.loggers.debug 'Not accepting potentially dangerous file transfer'
          return
        end
        
        name = Filename.find_by(name: dcc.filename)
        name ||= Filename.find_by(name: dcc.filename.gsub('_', ' '))

        if name.nil? || name.links.size <= 0
          admin.send("Couldn't Find: #{dcc.filename}")

          outdir = "#{Rails.root}/tmp/books"
          FileUtils.makedirs(outdir)
          out = "#{outdir}/#{dcc.filename}"
          File.open(out, 'wb') do |f|
            dcc.accept(f)
          end

          admin.send(" Saved To: #{out}")

          return
        end

        admin.send("Accepting: #{name}")

        if name.links.size > 1
          admin.send("Unexpected # of links: #{name.links.size}")
        end

        link = name.links.first
        mimetype = name.mimetype
        book = link.book
        outdir = "#{Rails.root}/public/book/by/#{book.author}/#{book.title}"
        FileUtils.makedirs(outdir)
        out = "#{outdir}/#{name.extension}"

        File.open(out, 'wb') do |f|
          dcc.accept(f)
        end

        admin.send("Saved: #{out}")

        if name.extension == 'rar'
          Dir.chdir(outdir)

          admin.send("Extracting: #{out}")

          system('rar x -y rar')
          File.unlink('rar')

          if (
            Dir.glob('*').size == 1 \
            && File.file?(Dir.glob('*').first)
          )
            f = Filename.new(
              name: Dir.glob('*').first
            )
            FileUtils.mv(
              f.name, f.extension
            )
            out = "#{outdir}/#{f.extension}"
            mimetype = f.mimetype
          else
            admin.send("RAR Difficulty In: #{outdir}")
          end
        end

        if File.file?(out)
          cmd = IO.popen(['ipfs', 'add', out], 'r+')
          out = cmd.readlines.first
          id = out.split[1]
          data = Datum.find_or_create_by(
            ipfs_id: id, mimetype: mimetype
          )

          admin.send("Saved: #{book} (#{mimetype}) => #{id}")

          name.links.each do |link|
            admin.send("Linking: #{link.book} & #{data.ipfs_id}")
            link.book.data << data
          end
        end

        dequeue(queue, admin, m.bot.channels[1])
      end
    end

    bot.start
  end

  task isfdb: :environment do |args, t|
    client = Mysql2::Client.new(
      host: 'localhost', database: 'isfdb'
    )
    types = client.query(
      'SELECT DISTINCT' \
      + ' award_type_id AS id,' \
      + ' award_type_short_name AS shortname,' \
      + ' award_type_name AS name' \
      + ' FROM award_types',
      symbolize_keys: true
    )
    types.each do |type|
      award = Award.find_or_create_by(
        name: type[:name],
        shortname: type[:shortname]
      )
      entries = client.query(
        'SELECT' \
        + ' award_title AS title,' \
        + ' award_author AS author,' \
        + ' award_cat_name AS cat,' \
        + ' award_year AS year' \
        + ' FROM awards' \
        + ' INNER JOIN award_cats' \
        + ' ON awards.award_cat_id = award_cats.award_cat_id' \
        + " WHERE award_type_id = #{type[:id]}",
        symbolize_keys: true,
        cast: false # dates are of form YYYY-00-00
      )
      entries.each do |entry|
        puts "#{entry[:cat]}: #{entry[:title]} by #{entry[:author]}"
        Entry.find_or_create_by!(
          award: award,
          year: Year.find_or_create_by!(
            number: entry[:year].sub(/-.*/, '')
          ),
          category: Category.find_or_create_by!(
            name: entry[:cat]
          ),
          won: true,
          nominee: Book.for(entry[:author], entry[:title])
        )
      end
    end
  end

  task(
    :gutenberg,
    [:dir] => [:environment]
  ) do |t, args|
    def saveBook(id, main, metas = [])
      if(match = (
        main.match(/^(.+),\s*(?:by|par|di)\s+(\S.*?)\s*$/i) \
        || main.match(/^(.+)\s+by\s+(\S.*?)\s*$/i)
      ))
        author = Author.find_or_create_by!(name: match[2])
        title = Title.find_or_create_by!(name: match[1])
      else
        author = nil
        title = Title.find_or_create_by!(name: main)
      end

      book = Book.find_or_create_by!(
        author: author, title: title
      )

      book.data << Datum.find_or_create_by!(
        gutenberg_id: id
      )

      puts "#{id}: #{title}#{author ? ", by #{author}" : ''}"
    end

    def processEntry(lines)
      begin
        lines.each{ |l| l.gsub!("\u00A0", ' ') } # nbsp not in \s
        if(!(match = lines[0].match(/^(\S.+?)\s+(\d+)(C?)\s*$/)))
          raise ArgumentError.new("Invalid Entry Start: #{lines[0]}")
        else
          main = match[1]
          id = match[2]
          copyright = !match[3].empty?
          current = main
          inMain = true
          metas = []

          lines[1..].each do |line|
            if(match = line.match(/^\s*\[(.+?)\]?\s*$/))
              inMain = false
              metas.push(match[1])
            elsif(match = line.match(/^\s+(\S.+?)\]?\s*$/))
              if inMain
                main += " #{match[1]}"
              else
                metas[-1] += " #{match[1]}"
              end
            else
              raise ArgumentError.new("Invalid Entry Continuation: #{line}")
            end
          end

          saveBook(id, main, metas)
        end
      rescue => e
        puts e
      end
    end

    Dir.glob("#{args[:dir]}/GUTINDEX.*").each do |file|
      prefaced = false
      inEntry = false
      lines = []

      if file.match?(/\d\d\d\d$/)
        puts "Processing: #{file}"
        File.readlines(file).each.with_index do |line, lineNum|
          if !prefaced
            #puts "  Skipping: #{line}"
            next if(prefaced = line.match?(/^TITLE and AUTHOR/))
          end
          next if !prefaced
          if line.match?(/^\s*$/)
            if inEntry
              processEntry(lines)
              lines = []
            end
            inEntry = false
            next
          end
          if inEntry && line.match?(/^\S/) && line[0] != '[' # GUTINDEX.2004
            processEntry(lines)
            lines = []
          end
          inEntry = true
          lines.push(line)
        end
        processEntry(lines) # last entry
      end
    end
  end
end
