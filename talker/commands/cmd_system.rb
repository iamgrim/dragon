# encoding: utf-8
module Commands
  require 'socket'
  
  define_command 'commands' do
    output box_title("Commands") + "\n" + box_text(Commands.names.join(", ").wrap(76)) + "\n" + bottom_line
  end

  define_command 'changes' do 
    output box_title("Recent Changes") + "\n" + box_textfile("changes") + "\n" + bottom_line
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
    output "#{Talker::NAME} - Version #{Talker::VERSION}\n"
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
    output box_title("Time") + "\n" + box_text(Time.now.strftime("Server time is %I:%M %p, %A %d %B %Y") + "\nTelnet is #{time_in_words(Time.now - Time.mktime(1969, 9, 25, 0, 0, 0, 0))} old") + "\n" + bottom_line
  end

  define_command 'examine' do |target_name|
    target = target_name.blank? ? self : find_entity(target_name)
    output (box_title("#{target.class.name} #{target.name}") + "\n" + box_text(target.examine) + "\n" + bottom_line) if target
  end
  define_alias 'examine', 'finger', 'profile', 'x'

  define_command 'settings' do |target_name|
    target = target_name.blank? ? self : find_entity(target_name)
    if target
      output box_title("Settings for #{target.name}") + "\n" + box_text(target.settings) + "\n" + bottom_line
    end
  end

  define_command 'who' do
    output box_title("Who") + "\n" +
      active_users.map { |u| sprintf("^B\u{2502}^n %15.15s %-59.59s ^B\u{2502}^n", u.name, u.title) }.join("\n") + "\n" + 
      bottom_line
  end
  define_alias 'who', 'w'

  define_command 'whod' do
    output box_title("Who Debug") + "\n" +
      active_users.map { |u| sprintf("^B\u{2502}^n %15.15s ^c%-59.59s ^B\u{2502}^n", u.name, "#{(u.charset == :unicode) ? '[unicod] ' : ''}#{u.debug ? '[debug] ' : ''}#{u.show_timestamps ? '[stamp collector]' : ''}") }.join("\n") + "\n" + 
      bottom_line
  end
  define_alias 'who', 'w'

  define_command 'connections' do
    output box_title("Connections") + "\n" +
      connected_users.values.map { |u| 
        c = u.active? ? "^G+" : "^W@"
        hostname = Socket.getaddrinfo(u.ip_address,nil)[0][2]
        sprintf("^B\u{2502}^n #{c}^n %-15.15s %-9.9s ^c%47.47s ^B\u{2502}^n", u.name, short_time(u.login_time), "#{hostname} (#{u.ip_address})") }.join("\n") + "\n" + 
      bottom_line
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
      buffer = box_title("User Activity") + "\n"
      active_users.each do |u|
        bars = sprintf("%-45s", ("\u{25a0}" * (((5400 - u.idle_time) / 120)+1)) + " #{u.idle_message}")
        buffer += sprintf("^B\u{2502}^n %15.15s %-77.77s ^B\u{2502}^n\n", u.name, "^C|^R#{bars.slice(0,15)}^C|^Y#{bars.slice(15,15)}^C|^G#{bars.slice(30,15)}^C| ^c#{short_time(u.idle_time)}^n")
      end
      buffer += bottom_line
      output buffer
    end
  end
  define_alias 'idle', 'active'

  define_command 'help' do
    buffer = box_title("Help")
    buffer += "
^B\u{2502}^n ^c  Basic talker commands:^n                                                    ^B\u{2502}^n
^B\u{2502}^n ^L  say^n         Speak to everyone                                             ^B\u{2502}^n
^B\u{2502}^n ^L  emote^n       Perform an action to everyone                                 ^B\u{2502}^n
^B\u{2502}^n ^L  who^n         Get a list of people who are connected                        ^B\u{2502}^n
^B\u{2502}^n ^L  tell^n        Speak to someone privately                                    ^B\u{2502}^n
^B\u{2502}^n ^L  commands^n    List all the available commands                               ^B\u{2502}^n
^B\u{2502}^n ^L  socials^n     List all the available socials (user defined actions)         ^B\u{2502}^n
^B\u{2502}^n ^L  examine^n     Get details about a user or social                            ^B\u{2502}^n
^B\u{2502}^n ^L  idle^n        Show when users were last active                              ^B\u{2502}^n
^B\u{2502}^n ^L  password^n    Set and password and reserve your user name for future visits ^B\u{2502}^n
"
    buffer += bottom_line
    output buffer
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
    output title_line("History") + "\n" + talker_history.to_s(get_timestamp_format) + "\n" + blank_line
  end
  define_alias 'history', 'recall', 'review'

  define_command 'myhistory' do
    output title_line("Your Private History") + "\n" + history.to_s(get_timestamp_format) + "\n" + blank_line
  end
  define_alias 'myhistory', 'rhistory'
  
  define_command 'social pull' do |social_name|
    if social_name.blank?
      output "Format: social pull <social name>"
    elsif valid_name?(social_name, :allow_bad_words => true)
      social_name.downcase!
      buffer = ""
      creator = ""
      begin
      result = open("http://wooooooooooooooy.com/socials/#{social_name}.txt") do |f|
        f.each_line do |line|
          buffer += line
          if line =~ /^creator/
            (token, value) = line.split(':', 2)
            creator = value.strip.downcase
          end
        end
      end
      rescue Exception => e
        if e.class == OpenURI::HTTPError && e.io.status[0] == "404"
          output "'#{social_name}' isn't on wooooooooooooooy.com."
        else
          debug_message "#{name} failed to pull social '#{social_name}': #{e}"
          output "Sorry, an error occurred when trying to pull the social. Please try again later."
        end
      else
        if creator != lower_name
          output "Sorry, only the creator can pull the social."
        else
          update = Social.socials.has_key?(social_name)

          File.open("import/socials/#{social_name}", "w") do |file|
            file.puts buffer
          end
          Social.import("import/socials/#{social_name}")
          if update
            debug_message "Social '#{social_name}' updated by #{name}"
            output "The social has been updated."
          else
            output_to_all "^Y\u{25ba}^n #{cname} creates the ^L#{social_name}^n social"
          end
        end
      end
    end
  end
  
  define_command 'social liquidate' do |social_name|
    if social_name.blank?
      output "Format: social liquidate <social name>"
    elsif social = find_social(social_name)
      if !social.created_by?(self)
        output "You need a full controlling share to liquidate the asset."
      else
        output "You have liquidated the social '#{social.name}'"
        social.delete
      end
    end
  end
  
  define_command 'socials' do |user_name|
    if user_name.blank?
      output box_title("Socials") + "\n" + box_text(Social.names.join(", ").wrap(76)) + "\n" + bottom_line
    elsif user = find_user(user_name)
      output box_title("Socials Owned By #{user.name}") + "\n" + box_text(Social.socials_by(user).map{|s| s.name}.join(", ").wrap(76)) + "\n" + bottom_line
    end
  end
  
end
