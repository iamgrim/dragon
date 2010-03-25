# encoding: utf-8
module Commands
  define_command 'idlemsg' do |message|
    if message.blank?
      output "Format: idlemsg <message>"
    else
      self.idle_message = message
      output "You set your idle message to:\n^L #{name} is inactive> #{idle_message}^n"
    end
  end
  
  define_command 'title' do |message|
    if message.blank?
      self.title = ""
      output "You now have no title"
    else
      self.title = message
      output "Your title is now:\n#{name} #{title}^n"
    end
    save
  end

 define_command 'location' do |message|
    if message.blank?
      self.location = ""
      output "You are now homeless"
    else
      self.location = message.slice(0, 60)
      output "Your location is now set to: #{location}^n"
    end
    save
  end

  define_command 'homepage' do |message|
    if message.blank?
      self.homepage = ""
      output "You now have no homepage"
    else
      self.homepage = message.slice(0, 60)
      output "Your homepage is now set to: ^B^U#{homepage}^n"
    end
    save
  end

  define_command 'occupation' do |message|
    if message.blank?
      self.occupation = ""
      output "You are now on the dole"
    else
      self.occupation = message.slice(0, 60)
      output "Your occupation is now set to: #{occupation}^n"
    end
    save
  end

  define_command 'realname' do |message|
    if message.blank?
      self.realname = ""
      output "You remain anonymous"
    else
      self.realname = message.slice(0, 60)
      output "Your real name is now set to: #{realname}^n"
    end
    save
  end

  define_command 'maritalstatus' do |message|
    changed = true
    if message == "single"
      self.maritalstatus = "single"
    elsif message == "attached"
      self.maritalstatus = "in a relationship"
    elsif message == "married"
      self.maritalstatus = "married"
    elsif message == "none"
      self.maritalstatus = ""
    else
      changed = false
    end
    
    if maritalstatus.blank? && changed
      output "Your marital status has been blanked."
    elsif maritalstatus.blank? && !changed
      output "Your marital status is not set.\nTo change it type ^Lmaritalstatus <single|attached|married|none>^n"
    elsif !maritalstatus.blank? && changed
      output "Your marital status has been changed to #{maritalstatus}."
    else  
      output "Your marital status is #{maritalstatus}.\nTo change it type ^Lmaritalstatus <single|attached|married|none>^n"
    end
    save
  end

  define_command 'connectmsg' do |message|
    if message.blank?
      self.connect_message = nil
    else
      self.connect_message = message.slice(0, 60)
    end
    output "Your connect message is now #{get_connect_message}"
    save
  end

  define_command 'disconnectmsg' do |message|
    if message.blank?
      self.disconnect_message = nil
    else
      self.disconnect_message = message.slice(0, 60)
    end
    output "Your disconnect message is now #{get_disconnect_message}"
    save
  end

  define_command 'reconnectmsg' do |message|
    if message.blank?
      self.reconnect_message = nil
    else
      self.reconnect_message = message.slice(0, 60)
    end
    output "Your reconnect message is now #{get_reconnect_message}"
    save
  end
  
  define_command 'gender' do |message|
    changed = true
    if message == "male"
      self.gender = :male
    elsif message == "female"
      self.gender = :female
    elsif message == "none"
      self.gender = nil
    else
      changed = false
    end
    if changed
      output "Your gender has been set to #{gender_text}."
    else
      output "Your gender is #{gender_text}, to change it type ^Lgender <female|male|none>^n"
    end
    save
  end

  define_command 'prompt' do |message|
    if message.blank?
      self.prompt = nil
      output "You will now receive the default prompt"
    elsif message == "off"
      self.prompt = ""
      output "You will no longer receive a prompt"
    else
      self.prompt = message
      output "Prompt changed"
    end
    save
  end
  
  define_command 'colour' do |message|
    if tripping
      output get_text("butterfly")
    else
      if message == "on"
        self.colour = :ansi
        output "^YColour output is on!^n"
      elsif message == "off"
        self.colour = :off
        output "Colour output is off"
      elsif message == "wands"
        self.colour = :wands
        output "You are now viewing colour wands."
      else
        output "Format: colour [on|off|wands]"
      end
      save
    end
  end
  define_alias 'colour', 'color'
  
  define_command 'recap' do |message|
    if message.blank? || message.downcase != lower_name
      output "Format: recap <your username in lower or uppercase letters>"
    else
      self.name = message
      output "Your name is now capitalised as #{name}."
      save
    end
  end
  
  define_command 'debug' do
    self.debug = !debug
    
    if debug
      output "You are viewing the debug channel."
    else
      output "You are no longer viewing the debug channel."
    end
    save
  end
  
  define_command 'ignore' do |target_name|
    if target_name =~ /^[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+$/
      self.ignoring_ips[target_name] = true
      output "You are now ignoring all users from #{target_name}"
    else
      target = find_user(target_name) unless target_name.blank?
      if target_name.blank? || target.nil?
        if ignoring.empty? && ignoring_ips.empty?
          output "Format: ignore <user name or ip address>"
        else
          output "You are ignoring #{commas_and(ignoring.keys + ignoring_ips.keys)}."
        end
      elsif target == self
        output "You can't ignore yourself."
      elsif is_ignoring?(target)
        output "You are already ignoring #{target.name}. Use ^Lunignore^n to remove it."
      else
        self.ignoring[target.lower_name] = true
        output "You are now ignoring #{target.name}."
      end
    end
  end
  
  define_command 'unignore' do |target_name|
    if target_name =~ /^[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+$/
      if ignoring_ips.has_key?(target_name)
        self.ignoring_ips.delete(target_name)
        output "You are no longer ignoring #{target_name}"
      else
        output "You were not ignoring ip address #{target_name}"
      end
    else
      target = target_name.blank? ? self : find_user(target_name)
      if target
        if target == self
          output "You can't ignore yourself."
        elsif !is_ignoring?(target)
          output "You were not ignoring #{target.name}."
        else
          self.ignoring.delete(target.lower_name)
          output "You are no longer ignoring #{target.name}."
        end
      end
    end
  end
  
  define_command 'charset' do |message|
    if message == "unicode" || message == "utf8"
      self.charset = :unicode
      output "Your character set is now ^Lunicode^n."
      save
    elsif message == "ascii"
      self.charset = :ascii
      output "Your character set is now ^Lascii^n."
      save
    else
      output "Your character set is currently ^L#{charset}^n.\nFormat: charset [unicode|ascii]"
    end
  end
  define_alias 'charset unicode', 'unicode', 'utf8'
  define_alias 'charset ascii', 'ascii'
  
  define_command 'timestamps' do |message|
    if message == "on"
      self.show_timestamps = true
    elsif message == "off"
      self.show_timestamps = false
    elsif message == "format"
      self.timestamp_format = nil
    elsif message =~ /^format (.*)/
      self.show_timestamps = true
      self.timestamp_format = $1
    end
    buffer = (show_timestamps ? "You are viewing timestamps" + (!timestamp_format.nil? ? ", with custom format: #{get_timezone.strftime(timestamp_format, Time.now)}^n (#{timestamp_format.gsub(/\^/, '^^')})^n" : ".") : "You are not viewing timestamps")
    buffer += "\nFormat: timestamps [on|off|format <string>]" if message.blank?
    output buffer
    save
  end

  define_command 'alias' do |message|
    (alias_name, alias_text) = get_arguments(message, 2)
    if alias_name.blank? || alias_text.blank?
      output "Format: alias <name> <text>"
    else
      self.aliases[alias_name] = Alias.new(alias_name, alias_text)
      output "Alias defined."
    end
  end

  define_command 'unalias' do |alias_name|
    if alias_name.blank?
      output "Format: unalias <name>"
    else
      if aliases.has_key?(alias_name)
        self.aliases.delete(alias_name)
        output "Alias removed."
      else
        output "You don't have an alias called '#{alias_name}' to remove."
      end
    end
  end
  
  define_command 'aliases' do |target_name|
    target = target_name.blank? ? self : find_entity(target_name)
    output box("Aliases for #{target.name}", target.aliases.values.map {|a|"^L#{a.name}^n #{a.text}^n"}.join("\n")) if target
  end
  
  define_command 'timezone find' do |message|
    if message.blank?
      output "Format: timezone [find <country>|server|<identifier>]"
    else
      if !TZInfo::Country.all_codes.index(message.upcase).nil?
        countrycode = message.upcase
      else
        lower_message = message.downcase
        countrycode = COUNTRIES_ISO3166_1[lower_message]
        if countrycode.nil?
          matches = COUNTRIES_ISO3166_1.keys.select {|n| n.downcase =~ /^#{Regexp.escape(lower_message)}/}
          if matches.length == 0
            output "Couldn't find any timezones corresponding to that country."
          elsif matches.length > 1
            output "Multiple possible countries: #{matches.join(', ')}."
          else
            countrycode = COUNTRIES_ISO3166_1[matches.first]
          end
        end  
      end
      
      if !countrycode.nil?
        tzcountry = TZInfo::Country.get(countrycode)
        output "Timezones within #{tzcountry.name}:"
        
        #len = active_users.map {|u|u.name.length}.max
        #sprintf("%#{len}.#{len}s %-#{75-len}.#{75-len}s", u.name, "#{u.title}^n")
        
        tzcountry.zone_identifiers.each do |timezone|
          output "^W#{timezone}^n"
        end
      end
    end
  end
  define_alias 'timezone find', 'tz find'
  
  define_command 'timezone' do |message|
    if message == "server"
      self.timezone_identifier = Talker::TIMEZONE
      output "Your timezone is now set to that of the server (#{Talker::TIMEZONE})"
      save
    elsif !message.blank?
      message = message.split('/').map {|part| part.split('_').map {|s| s.capitalize}.join('_')}.join('/')
      if !TZInfo::Timezone.all_identifiers.index(message).nil?
        self.timezone_identifier = message
        output "Your timezone is now set to ^W#{get_timezone_identifier}^n"
        save
      else
        output "Couldn't find that timezone."
      end
    else
      buffer = "Format: timezone [find <country>|server|<identifier>]\n"
      buffer += "Your timezone is ^W#{get_timezone_identifier}^n"
      output buffer
    end
  end
  define_alias 'timezone', 'tz'

end
