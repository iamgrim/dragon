# encoding: utf-8
module Talker
  require 'socket'
  
  define_command 'commands' do
    output box("The following commands are available to you", Talker.command_names.map{|c|TalkerBase.instance.on_fire.has_key?(c) ? "^R#{c}^n" : c}.join(", ").wrap(76))
  end

  define_command 'changes' do 
#    output box("Lateste writings from thy scribes", get_text("changes"))
    output get_text("changes")
  end
  
  define_command 'testcard' do
    output Textfile.get_text (charset == :unicode ? "testcard.unicode" : "testcard")
  end

  define_command 'pine' do 
    output Textfile.get_text "pine"
  end
  
  define_command 'bofh' do
    output Textfile.get_text "bofh"
  end

  define_command 'rules' do |name|
    if name.blank?
      output "Format: rules <game>"
    else
      text = Textfile.get_text "rules_#{name.downcase}"
      if text.blank?
        output "Sorry, the rules for #{name} are out of stock."
      else
        output text
      end
    end
  end
  
  define_command 'version' do
    output "#{TalkerBase::NAME} - Committe #{TalkerBase::VERSION}\nThou is inn #{TalkerBase::LIVE ? 'live' : 'development'} mode."
  end
  
  define_command 'idea' do |string|
    if string.blank?
      output "Format: idea <message>"
    else
      log 'idea', "#{self.name} #{string}"
      if string.downcase =~ /sword/
        output "Sorry, that idea is shit"
      else
        output "Thank you for thy idea, thoust will surely considere it."
      end
    end
  end

  define_command 'bug' do |message|
    if message.blank?
      output "Format: bug <message>"
    else
      log 'bug', "#{self.name} #{message}"
      output "Thanke you, I assure you this will be investigated with the greateste urgence."
    end
  end

  define_command 'quit' do
    output "Farewell #{name}, thou shalt hope to see you again soone!"
    disconnect
  end

  define_command 'time' do
    buffer = "Realm time is #{Time.now.strftime("%l:%M %p, %A %d %B %Y").strip}\n"
    buffer += get_timezone.strftime("Time in #{get_timezone_identifier} is %l:%M %p, %A %d %B %Y").strip + "\n" if get_timezone_identifier != TalkerBase::TIMEZONE
    buffer += "Tallnet is #{time_in_words(Time.now - Time.mktime(1969, 9, 25, 0, 0, 0, 0))} old\n"
    output box("Time", buffer)
  end

  define_command 'examine' do |target_name|
    target = target_name.blank? ? self : find_entity(target_name)
#    output box("#{target.class.name} #{target.name}", encode_string(target.examine, charset).wrap(75)) if target
    output encode_string(target.examine, charset) if target
  end
  define_alias 'examine', 'finger', 'profile', 'x'

  define_command 'settings' do |target_name|
    target = target_name.blank? ? self : find_user(target_name)
    if target    
      buffer = "     Title : #{target.name} #{target.title}\n"
      buffer += "     Login : #{target.get_connect_message}\n"
      buffer += "Disconnect : #{target.get_disconnect_message}\n"
      buffer += " Reconnect : #{target.get_reconnect_message}\n"
      buffer += "    Prompt : #{target.get_prompt}\n"
      buffer += "Timestamps : #{target.get_timestamp_format}\n" if show_timestamps
      output box("Settings for #{target.name}", buffer)
    end
  end

  define_command 'who' do
    len = active_users.map {|u|u.name.length}.max    
    output box("List Of Workers On Site", active_users.map { |u| sprintf("%#{len}.#{len}s %-#{75-len}.#{75-len}s", u.name, "#{Social.process_string(u.get_title, u, self, "")}^n") }.join("\n"))
  end
  define_alias 'who', 'w'

  define_command 'whod' do
    output box("Specialist Version Of Who For Welders", active_users.map { |u| sprintf("%15.15s ^c%-61.61s", u.name, "#{(u.charset == :unicode) ? '[Unicod] ' : ''}#{u.debug ? '[Welding] ' : ''}#{u.show_timestamps ? '[Stamp Collector] ' : ''}#{u.fishing && u.fishing.subscribed ? '[Angle] ' : ''}") }.join("\n"))
  end
  define_alias 'who', 'w'

  define_command 'connections' do
    output box("Connections", connected_users.values.map { |u| 
      c = u.active? ? "^G+" : "^W@"
      sprintf("#{c}^n %-15.15s %-9.9s ^c%47.47s", u.name, short_time(u.idle_time), "Connected from #{u.ip_address} for #{short_time(u.login_time)}")  
      }.join("\n"))
  end
  define_alias 'connections', 'connected', 'lsi'

  define_command 'look' do
    look
  end
  define_alias 'look', 'l'

  define_command 'idle' do |user_name|
    if !user_name.blank?
      u = find_connected_user(user_name)
      if u
        buffer = "  #{u.name} is #{time_in_words(u.idle_time)} idle." 
        buffer += "\n  > #{u.idle_message}^n" unless u.idle_message.blank?
        output buffer
      end
    else
      buffer = ""
      awake = 0
      active_users.each do |u|
        awake += 1 if u.idle_time < 1800
        bars = sprintf("%-45s", ("\u{25a0}" * (((5400 - u.idle_time) / 120)+1)) + " #{u.idle_message}")
        buffer += sprintf("%15.15s %-77.77s\n", u.name, "^C|^R#{bars.slice(0,15)}^C|^Y#{bars.slice(15,15)}^C|^G#{bars.slice(30,15)}^C| ^c#{short_time(u.idle_time)}^n")
      end
      total = active_users.length
      title_string = if total == 1
        "There is only you on the program at the moment"
      elsif awake == 1
        "There are #{total} people here, only one of whom appears to be awake"
      else
        "There are #{total} people here, #{awake} of whom appear to be awake"
      end
      output box(title_string, buffer)
    end
  end
  define_alias 'idle', 'active'

  define_command 'help' do
    buffer = "^c  Basic talker commands:^n
^L  say^n         Speak to everyone
^L  emote^n       Perform an action to everyone
^L  who^n         Get a list of people who are connected
^L  tell^n        Speak to someone privately
^L  commands^n    List all the available commands
^L  socials^n     List all the available socials (user defined actions)
^L  examine^n     Get details about a user or social
^L  idle^n        Show when users were last active
^L  password^n    Set and password and reserve your user name for future visits"
    output box("Help", buffer)
  end
  define_alias 'help', '?'
  
  define_command 'uptime' do
    buffer = "Connection server uptime: #{time_in_words(Time.now - TalkerBase.instance.connection_server_uptime)}\n"
    buffer += "Talk server uptime: #{time_in_words(Time.now - TalkerBase.instance.talk_server_uptime)}"
    output buffer
  end 

  define_command 'muffle' do
    self.muffled = !muffled
    
    if muffled
      buffer = "^Y<-^n #{name} wear ear muff ^Y->^n"
      output_to_all buffer
      output buffer
    else
      output_to_all"^Y->^n #{name} remove ear muff ^Y<-^n"
    end
  end

  define_command 'password' do
    if !resident? && login_time < 300
      output "Sorry, you need to be logged in for at least 5 minutes to set a password."
    else
      password_mode :on
      if resident?
        output "Please enter your current password."
        send_prompt "Old Password > "
        self.handler = :authenticate_for_change_password
      else
        output "Please enter a new password."
        send_prompt "New Password > "
        self.handler = :change_password
      end
    end
  end
  define_alias 'password', 'passwd'

  define_command 'history' do
    output title_line("Docks Work Log") + "\n" + talker_history.to_s(get_timestamp_format) + "\n" + blank_line
  end
  define_alias 'history', 'recall', 'review'

  define_command 'myhistory' do
    output title_line("Your Private History") + "\n" + history.to_s(get_timestamp_format) + "\n" + blank_line
  end
  define_alias 'myhistory', 'rhistory'
  
  define_command 'richlist' do |num|
    pos    = num.to_i
    start  = pos - 7
    start  = 0 if start < 0
    max    = all_users.length - 15
    start  = max if start > max
    result = all_users.values.sort{|u,u2|u2.money <=> u.money}.slice(start, 15)
    len    = result.map {|u|u.name.length}.max
    len2   = result.map {|u|currency(u.money).length}.max    
    count  = start
    output box("Forbes Rich List", result.map {|u| count += 1; "#{(pos == 0 && u == self) || pos == count ? '^L' : ''}#{sprintf("%2.d", count)}. #{sprintf("%-#{len}.#{len}s", u.name)} #{sprintf("%#{len2}s", currency(u.money))}"}.join("^n\n"))
  end
  define_alias 'richlist', 'forbes'
  
  define_command 'spuds' do
    spuds = ['King Edward', 'Duke of York', 'Jersey Royal', 'Maris Piper', 'Russet Burbank', 'Yukon Gold', 'Desiree', 'Charlotte', 'Rooster', 'Golden Wonder']
    result = all_users.values.sort{|u,u2|u2.total_login_time <=> u.total_login_time}.slice(0, 15)
    count = 0
    output box("Top Potato Growers", result.map {|u| count += 1; "#{u == self ? '^L' : ''}#{sprintf("%2.d", count)}. #{sprintf("%-15.15s", spuds[count - 1] || 'Smash')} #{sprintf("%-15.15s", u.name)} #{sprintf("%26.26s", short_time(u.total_login_time).gsub('d', ' potatoes, ').gsub('h', ' peelings'))}"}.join("^n\n"))
  end
  define_alias 'spuds', 'spods'
  
  define_command 'chart' do
    lastfm = Lastfm.new('cc7edc8072119a8875842b2646a64c0c', '0d262ccefa709548e3010a595ebb4bb1')
    group = Lastfm::Group.new(lastfm)
    count = 0
    artists = group.get_weekly_artist_chart('Dragon World Talker')['weeklyartistchart']['artist'].slice(0, 10).map do |artist|
      count = count + 1
      sprintf(" %2.2d. ^L%-53.53s^n ^c%15.15s", count, "#{artist['name']}", "(#{artist['playcount']} #{pluralise('play', artist['playcount'].to_i)})")
    end.join("\n")
    
    output box("Artist Of The Week", artists)
  end
  
  define_command 'tracks' do |target_name|
    target = target_name.blank? ? self : find_user(target_name)
    if target
      if target.lastfm.blank?
        output "#{target.name} needs to specify the name of their last.fm account using the ^Llastfm^n command."
      else
        lastfm = Lastfm.new('cc7edc8072119a8875842b2646a64c0c', '0d262ccefa709548e3010a595ebb4bb1')
        lfmuser = Lastfm::User.new(lastfm)
        recent_tracks = lfmuser.get_recent_tracks(target.lastfm)['recenttracks']['track']
        if recent_tracks.blank?
          output "#{target.name} doesn't have any recent tracks!"
        else
          tracks = recent_tracks.map do |track|
            date_string = if track.has_key?('@attr') && track['@attr'].has_key?('nowplaying')
              "Now"
            else
              "#{short_time(Time.now -  track['date']['uts'].to_i)}"
            end
            sprintf("%-68.68s ^c%6.6s", "#{track['artist']['#text']} - #{track['name']}", date_string)
          end.join("\n")
          output box("#{target.name} Recent Tracks. http://last.fm/user/#{target.lastfm}", tracks)
        end
      end
    end
  end
  
  define_command 'lastfm' do |message|
    if message.blank?
      self.lastfm = nil
      output "Format: lastfm <your last.fm profile name>"
    else
      self.lastfm = message
      output "Last.fm profile name set to #{message}."
    end
    save
  end
  
end
