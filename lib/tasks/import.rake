namespace :import do
  desc 'Import data from external sources'

  BANNED = ['bsk']

  task(
    :gutencache,
    [:dir] => [:environment]
  ) do |t, args|
    puts "Searching: #{args[:dir]}/*/*-images.epub"
    Dir.glob("#{args[:dir]}/*/*-images.epub").each do |epub|
      puts "Importing: #{epub}"

      # cmd = IO.popen(['ipfs', 'add', out], 'r+')
      # coverId = cmd.readlines.first

      # filename = %w[cover jpg]
      # ipfs.files.cp(new CID(coverId), filename)
      # containedId = ipfs.files.stat(:cover)

      # db.put({
      #   type: :file, ipfs_id: containedId,
      #   path: filename,
      # })

      # parent = %W[book #{book.fulltitle}]
      # ipfs.files.mkdir(parent)
      # branchId = ipfs.files.stat(:cover)
      # db.put({
      #   type: :context, branch_id: 
      # })
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
