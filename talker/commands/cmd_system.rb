# encoding: utf-8
module Commands
  require 'socket'
  
  define_command 'commands' do
    output box("Commands", Commands.names.map{|c|Talker.instance.on_fire.has_key?(c) ? "^R#{c}^n" : c}.join(", ").wrap(76))
  end

  define_command 'changes' do 
    output box("Recent Changes", get_text("changes"))
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
        output "Sorry, there are no rules for #{name}"
      else
        output text
      end
    end
  end
  
  define_command 'version' do
    output "#{Talker::NAME} - Commit #{Talker::VERSION}\nRunning in #{Talker::LIVE ? 'live' : 'development'} mode."
  end
  
  define_command 'idea' do |string|
    if string.blank?
      output "Format: idea <message>"
    else
      log 'idea', "#{self.name} #{string}"
      if string.downcase =~ /sword/
        output "Sorry, that idea is shit"
      else
        output "That's an excellent idea, thanks a lot."
      end
    end
  end

  define_command 'bug' do |message|
    if message.blank?
      output "Format: bug <message>"
    else
      log 'bug', "#{self.name} #{message}"
      output "Thank you, Merlin will look in to that as soon as possible."
    end
  end

  define_command 'quit' do
    output "Goodbye #{name}"
    disconnect
  end

  define_command 'time' do
    buffer = "Server time is #{Time.now.strftime("%l:%M %p, %A %d %B %Y").strip}\n"
    buffer += get_timezone.strftime("Time in #{get_timezone_identifier} is %l:%M %p, %A %d %B %Y").strip + "\n" if get_timezone_identifier != Talker::TIMEZONE
    buffer += "Telnet is #{time_in_words(Time.now - Time.mktime(1969, 9, 25, 0, 0, 0, 0))} old\n"
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
      buffer = "     Title : #{name} #{title}\n"
      buffer += "     Login : ^g\u{25ba}^G\u{25ba} ^n#{name} #{get_connect_message} ^G\u{25c4}^g\u{25c4}\n"
      buffer += "Disconnect : ^R\u{25c4}^r\u{25c4} ^n#{name} #{get_disconnect_message} ^r\u{25ba}^R\u{25ba}\n"
      buffer += " Reconnect : ^Y\u{25ba}^y\u{25c4} ^n#{name} #{get_reconnect_message} ^y\u{25ba}^Y\u{25c4}\n"
      buffer += "    Prompt : #{get_prompt}\n"
      buffer += "Timestamps : #{get_timestamp_format}\n" if show_timestamps
      output box("Settings for #{target.name}", buffer)
    end
  end

  define_command 'who' do
    len = active_users.map {|u|u.name.length}.max    
    output box("Who", active_users.map { |u| sprintf("%#{len}.#{len}s %-#{75-len}.#{75-len}s", u.name, "#{u.title}^n") }.join("\n"))
  end
  define_alias 'who', 'w'

  define_command 'whod' do
    output box("Who Debug", active_users.map { |u| sprintf("%15.15s ^c%-61.61s", u.name, "#{(u.charset == :unicode) ? '[unicod] ' : ''}#{u.debug ? '[debug] ' : ''}#{u.show_timestamps ? '[stamp collector]' : ''}") }.join("\n"))
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
      output box("User Activity", buffer)
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
    output title_line("History") + "\n" + talker_history.to_s(get_timestamp_format, get_timezone) + "\n" + blank_line
  end
  define_alias 'history', 'recall', 'review'

  define_command 'myhistory' do
    output title_line("Your Private History") + "\n" + history.to_s(get_timestamp_format, get_timezone) + "\n" + blank_line
  end
  define_alias 'myhistory', 'rhistory'
end
