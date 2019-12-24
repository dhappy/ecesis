namespace :import do
  desc 'Import data from external sources'

  BANNED = []

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
        admin.send("Notice: #{m.message}")
      end

      on :dcc_send do |m, dcc|
        if dcc.from_private_ip? || dcc.from_localhost?
          m.bot.loggers.debug 'Not accepting potentially dangerous file transfer'
          return
        end
        
        name = Filename.find_by(name: dcc.filename)
        name ||= Filename.find_by(name: dcc.filename.gsub('_', ' '))

        if name.nil?
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

        if name.links.size <= 0
          admin.send("No Links: #{name}")
          return
        end
        
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

          if Dir.glob('*.epub').size == 1
            FileUtils.mv(Dir.glob('*.epub').first, 'epub')
            out = "#{outdir}/epub"
            mimetype = 'application/epub+zip'
          elsif Dir.glob('*.html').size == 1
            FileUtils.mv(Dir.glob('*.html').first, 'html')
            out = "#{outdir}/html"
            mimetype = 'application/html'
          else
            admin.send("RAR Difficulty In: #{outdir}")
          end
        end

        if File.exist?(out)
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
    results = client.query(
      'SELECT * FROM awards LIMIT 10',
      cast: false # dates are of form YYYY-00-00
    )
    results.each do |row|
      puts "#{row['award_title']} by #{row['award_author']}"
    end
  end
end