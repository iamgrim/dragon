# encoding: utf-8
class User
  include Helpers
  
  attr_accessor :name
  attr_accessor :gender
  attr_accessor :first_seen
  attr_accessor :last_activity
  attr_accessor :last_login
  attr_accessor :total_time
  attr_accessor :total_connections
  attr_accessor :colour
  attr_accessor :timezone_identifier

  attr_accessor :prompt
  attr_accessor :title

  attr_accessor :connect_message
  attr_accessor :disconnect_message
  attr_accessor :reconnect_message

  attr_accessor :money
  attr_accessor :donations
  attr_reader   :rank
  attr_accessor :debug, :onduty

  attr_accessor :location, :homepage, :occupation, :maritalstatus, :realname, :lastfm

  attr_accessor :memos

  attr_accessor :fishing, :community_service, :rally
  attr_accessor :tripping, :bile, :vomited_on, :drug_strength, :prayer_status, :alcohol_units, :last_drink
  attr_accessor :brummed, :wossed, :sneezed_on
  attr_accessor :prison, :on_phone

  attr_accessor :id, :handler, :ip_address, :charset, :show_timestamps, :timestamp_format

  attr_accessor :idle_message, :muffled
  attr_reader :history, :aliases, :ignoring, :ignoring_ips

  RANK = ['Dock Worker', 'Shipman', 'Boat Swine', 'Crane Operator', 'Cargo Inspector', 'Captain', 'HCAdmiral']
  RANK_COLOUR = ['', '^y', '^Y', '^G', '^C', '^P', '^R']

  def initialize(name)
    @name = name
    set_initial_values
  end
  
  # called for new and existing users
  def set_initial_values
    now = Time.now
    @first_seen ||= now
    @last_activity ||= now
    @total_connections ||= 0
    @total_time ||= 0
    @money ||= 0
    @donations ||= 0
    @rank ||= 0
    @colour ||= :ansi
    @muffled ||= false
    @history ||= History.new
    @aliases ||= {}
    @ignoring ||= {}
    @ignoring_ips ||= {}
    @drug_strength ||= 0
    @alcohol_units ||= 0
    @onduty = @onduty.nil? ? true : @onduty
  end

  def lower_name
    name.downcase
  end

  def is_ignoring?(user)
    ignoring.has_key?(user.lower_name) || ignoring_ips.has_key?(user.ip_address)
  end

  def password=(password)
    @password = password.crypt("el")
  end

  def password_matches?(attempt)
    @password == attempt.crypt("el")
  end

  def crypted_password=(crypted_password)
    @password = crypted_password
  end

  def resident?
    !@password.nil?
  end
  
  def save
    f = File.new(data_file_name, "w")
    f.puts YAML.dump(self)
    f.close 
  end
  
  def delete
    File.delete(data_file_name) if FileTest.exist?(data_file_name)
  end

  def developer?
    !TalkerBase::LIVE || ["thebear", "sockeye", "felix"].include?(lower_name)
  end

  def complete_login(connection)
    old_id = @id
    @id = connection.id
    @total_connections = @total_connections + 1
    @last_activity = @last_login = Time.now
    @ip_address = connection.ip_address
    @muffled = false
    
    
    if resident?
#      output box("Recent Changes", get_text("changes"))
      output get_text("changes")
    else
      output get_text("welcome_newuser")
    end

    old_connection = connections[old_id]

    if old_connection.nil?
      connected_users[lower_name] = self
      output_to_all get_connect_message
    else
      old_connection.output "[Reconnection from #{connection.ip_address}]"
      old_connection.disconnect
      output_to_all get_reconnect_message
    end
    
    look
    user_prompt
  end

  def authenticate_for_change_password(password)
    if password_matches?(password)
      output "Please enter a new password."
      send_prompt "New Password > "
      self.handler = :change_password
    else
      output "Sorry, Incorrect password!"
      self.handler = nil
      password_mode :off
    end
  end
  
  def change_password(password)
    if password.length < 3 || password.length > 8
      output "New password must be between 3 and 8 characters long!"
      send_prompt "New Password > "
    else
      was_resident = resident?
      self.password = password
      save
      if !was_resident
        output "Thank you for setting a password. Your name is now reserved for future visits."
        output_to_all "^G\u{2192} ^n#{name} has been granted citizenship of thy realme by immigration officials!"
      else
        output "Password Changed."
      end
      self.handler = nil
      password_mode :off
    end
  end

  def logout
    connected_users.delete(lower_name)
    @id = nil
    output_to_all get_disconnect_message
    
    if !resident?
      delete
    else
      self.total_time += login_time
      save
    end
  end

  def logged_in?
    !@id.nil?
  end

  def active?
    idle_time < 5400
  end

  def gender_text
    gender ? gender.to_s : 'none'
  end

  def get_prompt
    Social.process_string(@prompt || "Dockyard> ", self, nil, "")
  end
  
  def get_timestamp_format
    @timestamp_format.blank? ? "^c%H:%M" : @timestamp_format
  end
  
  def get_timestamp
    @show_timestamps ? get_timezone.strftime(get_timestamp_format) + '^n ' : ''
  end
  
  def get_timezone
    TZInfo::Timezone.get(get_timezone_identifier)
  end
  
  def get_timezone_identifier
    @timezone_identifier || TalkerBase::TIMEZONE
  end
  
  def get_connect_message
    "^g>^G> ^n#{name} #{Social.process_string(@connect_message || 'clocks in with a loud *POP*', self, nil, "")} ^G<^g<^n"
  end

  def get_disconnect_message
    "^R<^r< ^n#{name} #{Social.process_string(@disconnect_message || 'clocks out with a loud *POP*', self, nil, "")} ^r>^R>^n"
  end

  def get_reconnect_message
    "^Y>^y< ^n#{name} #{Social.process_string(@reconnect_message || "shimmers for a moment as #{heshe} re-connects", self, nil, "")} ^y>^Y<^n"
  end

  def get_title
    title || "the newbie, so treat me nicely."
  end

  def user_prompt
    send_prompt(get_prompt)
  end

  def handle_input(input_string)
    user_alias_executing = !@input_string.nil?
    @input_string = input_string
    if handler
      send(handler, input_string)
    else
      unless input_string.empty?
        @idle_message = nil

        (command_name, body) = split_input(input_string)
        command = find_with_partial_matching(aliases, command_name, :silent => true) unless user_alias_executing
        command = find_command(command_name.downcase) if command.nil?
        if command
          command.execute(self, (body || "").gsub(/(\^+)$/, '').strip)
        end
      
        if !active? && memos.length > 0
          output "You have #{memos.length.to_s} unread #{pluralise('memo', memos.length)}."
        end
        @last_activity = Time.now
      end
    end
    user_prompt if handler.nil?
    if colourise(input_string, false) =~ /cheese/
      output_to_all "^Y- = > #{name} is being booted for being a cheesy so-and-so < = -"
      disconnect
    end
    @input_string = nil
  end

  def execute_parent_command(parent_name)
    c = find_command(parent_name)
    (command_name, body) = split_input(@input_string)
    c.execute(self, body, :sub_command => false)
  end


  def idle_time
    Time.now - self.last_activity
  end
  
  def login_time
    Time.now - self.last_login
  end

  def promote!
    if can_afford_promotion? && rank < 6
      self.money -= next_rank_cost
      @rank += 1
    end
  end
  
  def demote!
    @rank -= 1 if @rank > 0
  end
  
  def next_rank_cost
    1000000 * (2 ** rank)
  end
  
  def can_afford_promotion?
    money >= next_rank_cost
  end

  def rank_name
    RANK[rank]
  end
  
  def rank_name_with_colour
    r = onduty ? rank : 0
    "#{RANK_COLOUR[r]}#{RANK[r]}^n"
  end

  def cname
    "#{RANK_COLOUR[onduty ? rank : 0]}#{name}^n"
  end
  
  def hisher
    @gender == :male ? "his" : "her"
  end

  def himher
    @gender == :male ? "him" : "her"
  end
  
  def heshe
    @gender == :male ? "he" : "she"
  end
  
  def total_login_time
    logged_in? ? total_time + login_time : total_time
  end
  
  def examine
#    buffer = "       First seen : #{get_timezone.strftime("%l:%M %p, %A %d %B %Y", first_seen).strip}\n"
    buffer = blank_line + "#{name} #{Social.process_string(get_title, self, self, "")}\n" + blank_line
    if logged_in? && active?
      buffer += "       Login time : #{time_in_words(login_time)}\n"
      buffer += "        Idle time : #{time_in_words(idle_time)}\n"
    else
      buffer += "        Last seen : #{get_timezone.strftime("%l:%M %p, %A %d %B %Y", last_activity).strip}\n"
    end
    buffer += " Total login time : #{time_in_words(total_login_time)}\n"
    buffer += "      Connections : #{total_connections}\n"
    buffer += "             Rank : #{rank_name_with_colour}\n"
    buffer += "        Real name : #{realname}^n\n" unless realname.blank?
    
    gender_symbol = case gender
      when :male then "Male \u{2642}"
      when :female then "Female \u{2640}"
      else "None"
    end
    
    buffer += "           Gender : #{gender_symbol}\n"
    buffer += "           Drogna : #{currency(money)}\n"
    buffer += "   Marital Status : #{maritalstatus.capitalize}^n\n" unless maritalstatus.blank?
    buffer += "         Location : #{location}^n\n" unless location.blank?
#    buffer += "     Zone of Tyme : #{get_timezone_identifier.gsub(/_/, ' ')}^n\n" unless get_timezone_identifier == "Europe/London"
    buffer += "       Occupation : #{occupation}^n\n" unless occupation.blank?
    buffer += "         Homepage : ^U^B#{homepage}^n\n" unless homepage.blank?
    if fishing
      buffer += "          Fishing : #{Fishing::pounds_oz(fishing.combined_catch_total)} combined records total [#{Fishing::ranking(self).ordinal}]^n\n"
    end
    buffer + blank_line
  end
  
  def items
    @items ||= Items.new
  end
  
  def memos
    @memos ||= []
  end
  
  def send_memo(from, message)
    memos.push Memo.new(self, from, message)
    save
  end
  
  def self.load(name)
    lower_name = name.downcase
    if FileTest.exist?("data/users/#{lower_name}.yml") 
      f = File.new("data/users/#{lower_name}.yml", "r")
      user = YAML.load(f.read)
      f.close
    end
    user.set_initial_values
    user
  end

  def send_to_prison(reason)
    output_to_all "^R\u{2192} #{name} has been sent to prison for #{reason}!^n"
    self.prison = Time.now
    output "\n\nYou are in prison, plan on spending quite some time here...\n\n"
  end
  
  def release_from_prison
    output_to_all "^W\u{2192}^n #{name} has been released from prison early for good behaviour."
    self.prison = nil
    self.on_phone = nil
    save
    output "\nYou have been released from prison early for good behaviour.\n"
    look
  end

  def self.add(name, connection_id)
    u = User.new
    u.name = name
    u.connection_id = connection_id
    u.save
    @users[name.downcase] = u
  end

  def self.load_all
    users = {}
    Dir["data/users/*.yml"].each do |file_name|
      f = File.new(file_name, "r")
      name = File.basename(file_name, ".yml")
      users[name] = User.load(name)
      f.close
    end
    users
  end

  def self.import
    IO.readlines("import/users/userids").each do |line|
      (name, id) = line.strip.split(' : ')
      if FileTest.exist?("import/users/#{id}.user")
        puts "#{name}/#{id}"
        u = User.new(name)
        IO.readlines("import/users/#{id}.user").each do |line|
          (field, value) = line.strip.split(' : ')
          case field
          when "password" then u.crypted_password = value
          when "first_save_stamp" then u.first_seen = Time.at(value.to_i)
          when "total_time" then u.total_time = value.to_i
          when "total_connections" then u.total_connections = value.to_i
          when "prompt" then u.prompt = value
          when "title" then u.title = value
          when "gronda" then u.money = value.to_i
          when "gender" then u.gender = value == "2" ? :male : (value == "1" ? :female : nil)
          when "debug" then u.debug = (value.to_i > 0)
          end
        end
        u.save
      end
    end
  end
  
  private

  def split_input(string)
    if string =~ /(^\W)/
      [$1.strip, string.sub(/(^\W)/,'')]
    else
      string.split(' ', 2)
    end
  end

  def data_file_name
    "data/users/#{lower_name}.yml"
  end  
end
