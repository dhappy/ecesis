namespace :search do
  desc 'Search for missing data'

  task irc: :environment do
    require "cinch"
    require "cinch/helpers"

    bot = Cinch::Bot.new do
      configure do |c|
        c.server   = "irc.irchighway.net"
        c.channels = ['#cinch-bots', '#ebooks']
        c.nick = 'hugobot_v1'
      end

      on :message, /idx (.*)/ do |m|
        svr = m.message.sub(/^idx /, '')
        m.reply "Requesting List from '#{svr}' in #ebooks"
        m.bot.channels[1].send("@#{svr}")
      end

      on :message, /bb/ do |m|
        byebug
      end

      on :dcc_send do |m, dcc|
        if dcc.from_private_ip? || dcc.from_localhost?
          m.bot.loggers.debug "Not accepting potentially dangerous file transfer"
          return
        end

        admin.send("Accepting: #{dcc.filename}")
        filename = "#{Rails.root}/tmp/#{dcc.filename}"

        File.open(filename, 'wb') do |f|
          dcc.accept(f)
        end

        admin.send("Saved: #{dcc.filename}")

        Zip::File.open(filename) do |zipfile|
          zipfile.each do |file|
        end
      end

      on :privmsg do |m|
        puts "Here"
        if m.message =~ /^\001DCC SEND (?:"([^"]+)"|(\S+)) (\S+) (\d+)(?: (\d+))?\001$/
          puts "Match Vanilla SEND"
        elsif match = m.message.match(/^\u0001DCC SEND (?:"([^"]+)"|(\S+)) (\S+) (\d+)(?: (\d+))?(?: (\d+))?\u0001$/)
          require 'ipaddr'

          filename = match[1] || match[2]
          IPAddr.new(match[3], Socket::AF_INET6)

          puts "Reverse Send"
          byebug
        end
      end
    end
    bot.start
  end
end