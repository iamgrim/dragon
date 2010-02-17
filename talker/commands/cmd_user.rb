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
      self.title = message.slice(0, 60)
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
    output "Your connect message is now ^g>^G> ^n#{name} #{get_connect_message} ^G<^g<^n"
    save
  end

  define_command 'disconnectmsg' do |message|
    if message.blank?
      self.disconnect_message = nil
    else
      self.disconnect_message = message.slice(0, 60)
    end
    output "Your disconnect message is now ^R<^r< ^n#{name} #{get_disconnect_message} ^r>^R>^n"
    save
  end

  define_command 'reconnectmsg' do |message|
    if message.blank?
      self.reconnect_message = nil
    else
      self.reconnect_message = message.slice(0, 60)
    end
    output "Your reconnect message is now ^Y>^y< ^n#{name} #{get_reconnect_message} ^y>^Y<^n"
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
    buffer = (show_timestamps ? "You are viewing timestamps" + (!timestamp_format.nil? ? ", with custom format: #{Time.now.strftime(timestamp_format)}^n (#{timestamp_format.gsub(/\^/, '^^')})^n" : ".") : "You are not viewing timestamps")
    buffer += "\nFormat: timestamps [on|off|format <string>]" if message.blank?
    output buffer
  end
      
end
