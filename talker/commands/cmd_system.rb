# encoding: utf-8
module Commands
  require 'socket'
  
  define_command 'commands' do
    output box("Choose thoust command from thy following options", Commands.names.map{|c|Talker.instance.on_fire.has_key?(c) ? "^R#{c}^n" : c}.join(", ").wrap(76))
  end

  define_command 'changes' do 
    output box("Lateste writings from thy scribes", get_text("changes"))
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
    output "#{Talker::NAME} - Committe #{Talker::VERSION}\nThou is inn #{Talker::LIVE ? 'live' : 'development'} mode."
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
    buffer += get_timezone.strftime("Time in #{get_timezone_identifier} is %l:%M %p, %A %d %B %Y").strip + "\n" if get_timezone_identifier != Talker::TIMEZONE
    buffer += "Tallnet is #{time_in_words(Time.now - Time.mktime(1969, 9, 25, 0, 0, 0, 0))} old\n"
    output box("Time", buffer)
  end

  define_command 'examine' do |target_name|
    target = target_name.blank? ? self : find_entity(target_name)
    output box("#{target.class.name} #{target.name}", encode_string(target.examine, charset).wrap(75)) if target
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
    output box("Dr Who", active_users.map { |u| sprintf("%#{len}.#{len}s %-#{75-len}.#{75-len}s", u.name, "#{u.title}^n") }.join("\n"))
  end
  define_alias 'who', 'w'

  define_command 'whod' do
    output box("Ist thy specialyst version of who for scribe", active_users.map { |u| sprintf("%15.15s ^c%-61.61s", u.name, "#{(u.charset == :unicode) ? '[unicod] ' : ''}#{u.debug ? '[debuge] ' : ''}#{u.show_timestamps ? '[stamp collector] ' : ''}#{u.fishing && u.fishing.subscribed ? '[bisect] ' : ''}") }.join("\n"))
  end
  define_alias 'who', 'w'

  define_command 'connections' do
    output box("Peasants on thy realm including those attending slumber parties", connected_users.values.map { |u| 
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
        buffer = "  #{u.name} is #{time_in_words(u.idle_time)} inactive." 
        buffer += "\n  > #{u.idle_message}^n" unless u.idle_message.blank?
        output buffer
      end
    else
      buffer = ""
      active_users.each do |u|
        bars = sprintf("%-45s", ("\u{25a0}" * (((5400 - u.idle_time) / 120)+1)) + " #{u.idle_message}")
        buffer += sprintf("%15.15s %-77.77s\n", u.name, "^C|^R#{bars.slice(0,15)}^C|^Y#{bars.slice(15,15)}^C|^G#{bars.slice(30,15)}^C| ^c#{short_time(u.idle_time)}^n")
      end
      output box("Active peasants on thy realme", buffer)
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
    buffer = "Connection server uptime: #{time_in_words(Time.now - Talker.instance.connection_server_uptime)}\n"
    buffer += "Talk server uptime: #{time_in_words(Time.now - Talker.instance.talk_server_uptime)}"
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
    output title_line("Respect thy Worlde Histore") + "\n" + talker_history.to_s(get_timestamp_format, get_timezone) + "\n" + blank_line
  end
  define_alias 'history', 'recall', 'review'

  define_command 'myhistory' do
    output title_line("Your Private History") + "\n" + history.to_s(get_timestamp_format, get_timezone) + "\n" + blank_line
  end
  define_alias 'myhistory', 'rhistory'
  
  define_command 'richlist' do |num|
    pos    = num.to_i
    start = pos - 7
    start = 0 if start < 0
    result = all_users.values.sort{|u,u2|u2.money <=> u.money}.slice(start, 15)
    len    = result.map {|u|u.name.length}.max
    len2   = result.map {|u|currency(u.money).length}.max    
    count  = start
    output box("Forbes Dragon World Rich List", result.map {|u| count += 1; "#{(pos == 0 && u == self) || pos == count ? '^L' : ''}#{sprintf("%2.d", count)}. #{sprintf("%-#{len}.#{len}s", u.name)} #{sprintf("%#{len2}s", currency(u.money))}"}.join("^n\n"))
  end
  
end
