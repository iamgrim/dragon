# encoding: utf-8
module Helpers
  include TalkerUtilities
    
  def output_to_all(message, options={:show_timestamps => true})
    connected_users.values.each { |u| u.output "#{options[:show_timestamps] ? u.get_timestamp : ''}#{message}" unless u.muffled || u.is_ignoring?(self) }
  end

  def output_to_some(message, options={:show_timestamps => true}, &block)
    connected_users.values.each { |u| u.output "#{options[:show_timestamps] ? u.get_timestamp : ''}#{message}" if !(u.muffled || u.is_ignoring?(self)) && yield(u) }
  end
  
  def channel_output(message)
    message = sneeze_string(message) if sneezed_on
    message = vomit_string(message) if vomited_on
    
    connected_users.values.each do |u| 
      unless u.muffled || u.is_ignoring?(self)
        u.output "#{u.get_timestamp}#{message}"
      end
    end
    talker_history.add message
  end
  
  def find_with_partial_matching(hash, name, options={})
    return nil if name.blank?
    lower_name = name.downcase
    u = hash[lower_name]
    if u.nil? && !options[:exact_match] # try partial match
      matches = hash.keys.select {|n| n =~ /^#{Regexp.escape(lower_name)}/}
      if matches.length == 0
        output "A match for \'#{name}\' could not be found." unless options[:silent]
      elsif matches.length > 1
        output "Multiple name matches: #{matches.join(', ')}."  unless options[:silent]
      else
        u = hash[matches.first]
      end
    end
    u
  end
  
  def find_user(name, options={})
    find_with_partial_matching(all_users, name, options)
  end
  
  def find_users(names)
    users = names.split(/,/).map {|name| find_user(name)}
    users.include?(nil) ? nil : users
  end
    
  def find_connected_user(name, options={})
    find_with_partial_matching(connected_users, name, options)
  end

  def find_connected_users(names)
    users = names.split(/,/).map {|name| find_connected_user(name)}
    users.include?(nil) ? nil : users
  end

  def find_social(name, options={})
    find_with_partial_matching(socials, name, options)
  end

  def find_entity(name)
    type = nil
    (type, name) = name.split(' ', 2) if name =~ / /
    if type == "user"
      find_user(name)
    elsif type == "social"
      find_social(name)
    else
      find_with_partial_matching(socials.merge(all_users), name)
    end
  end
  
  def find_command(command_name)
    command = find_with_partial_matching(Talker.command_list, command_name)
    if command.nil?
      log 'unknown', "#{self.name} #{command_name}"
    end
    command
  end
  
  def find_multi(target_names)
    if target_names =~ /^[1-9]/
      m = Multi.find(target_names.to_i)
      if m.nil?
        output "Multi (#{target_names.to_i}) does not exist."
      elsif !m.member?(self)
        output "You are not a member of multi (#{target_names.to_i})"
        m = nil
      end
      m
    else
      Multi.find_or_create(find_connected_users(target_names + ",#{name}"))
    end
  end

  def lookup_user(name)
    TalkerBase.instance.all_users[name.downcase]
  end
  
  def all_users
    TalkerBase.instance.all_users
  end

  def connected_users
    TalkerBase.instance.connected_users
  end

  def active_users
    connected_users.values.select {|u| u.active?}
  end

  def socials
    Social.socials
  end
  
  def output_with_history(message)
    history.add(message) # add to the users personal history buffer
    output "#{get_timestamp}#{message}"
  end
  
  def output(message)
#    message = message.gsub(/([aeiou])/) {|s| (rand(4) == 0 ? ["ll", 'y', 'ys'][rand(3)] : $1)} 
    if tripping && drug_strength > 1
      message = message.gsub(/([a-z])/) {|s| (rand(2) > 0 ? $1.upcase : $1)}
      message = case drug_strength
      when 2 then random_interleave(colourise(message, false), ["^a", "^A", "", "", ""])
      when 3 then random_interleave(colourise(message, false), ["^a", "^A", "^a", "^A", ""])
      when 4 then random_interleave(colourise(message, false), ["^a", "^A"])
      when 5 then random_interleave(colourise(message, false), ["^a", "^A", "^a", "^A", "^d"])
      when 6 then random_interleave(colourise(message, false), ["^a", "^A", "^a", "^d", "^d"])
      when 7 then random_interleave(colourise(message, false), ["^a", "^A", "^d", "^d", "^d"])
      else        random_interleave(colourise(message, false), ["^a", "^d", "^d", "^d", "^d"])
      end
    end
    buffer = "\r" + colourise(encode_string(message, charset), self.colour).gsub("\n", "\\n") + "\033[0K\\n"
    buffer += (colourise(encode_string(get_prompt, charset), self.colour) + "\377\371") if TalkerBase.instance.current_id != id
    raw_send buffer
  end
  
  def send_prompt(message)
    raw_send "\r#{colourise(encode_string(message, charset), self.colour)}\377\371"
  end

  def password_mode(state)  # IAC WILL ECHO  # IAC WONT ECHO
    raw_send (state == :on ? "\377\373\001" : "\377\374\001")
  end
  
  def disconnect
    TalkerBase.instance.output << "#{id} disconnect"
  end
    
  def connections # the connected sockets
    TalkerBase.instance.connections
  end
  
  def output_inactive_message(user)
    output " ^L #{user.name} is inactive> #{user.idle_message}^n" if !user.idle_message.blank?
  end
  
  def get_text(name)
    Textfile.get_text(name)
  end
  
  def debug_message(message)
    TalkerBase.instance.debug_message(message)
  end
  
  def log(log_file, text)
    File.open("logs/#{log_file}", "a") {|f| f.puts "#{Time.now.strftime("%Y-%m-%d %H:%M")} #{text}"}
  end
  
  def reboot
    if developer?
      debug_message "Rebooting thy realme..."
      @input_string = nil
      TalkerBase.instance.save
      TalkerBase.instance.shutdown = true
    end
  end

  def shutdown
    if developer?
      TalkerBase.instance.output << "0 shutdown\n"
      @input_string = nil
      TalkerBase.instance.save
      EM.next_tick { sleep 3; EM.stop_event_loop }
    end
  end
  
  def look
    num = active_users.length
    buffer = "#{commas_and(active_users.map{|u|u.name})} #{is_are(num)} standing under a horse chestnut tree.\n"
    num = TalkerBase.instance.conkers_on_ground
    if num > 0
      buffer += "There #{is_are(num)} ^L#{num} #{pluralise('conker', num)}^n on the ground.\n"
    end
    num = TalkerBase.instance.sticks_on_ground
    if num > 0
      buffer += "There #{is_are(num)} ^L#{num} #{pluralise('stick', num)}^n on the ground.\n"
    end
    output buffer
  end
  
  def talker_history
    TalkerBase.instance.history
  end
  
  # send fully formatted message to a connection
  # use 'output' instead of this
  def raw_send(message)
    TalkerBase.instance.output << "#{id} send #{message}"
  end

end
