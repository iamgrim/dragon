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
  attr_accessor :debug

  attr_accessor :location
  attr_accessor :homepage
  attr_accessor :occupation
  attr_accessor :maritalstatus
  attr_accessor :realname

  attr_accessor :memos

  attr_accessor :fishing, :community_service
  attr_accessor :tripping, :bile, :vomited_on

  attr_accessor :id, :handler, :ip_address, :charset, :show_timestamps, :timestamp_format

  attr_accessor :idle_message, :muffled
  attr_reader :history, :aliases, :ignoring

  RANK = ['Peasant', 'Beadle', 'Knight', 'Baron', 'Earl', 'Princess', 'King']
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
  end

  def lower_name
    name.downcase
  end

  def is_ignoring?(user)
    ignoring.has_key?(user.lower_name)
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
    developers = Talker::LIVE ? ["thebear", "felix"] : ["thebear", "felix", "kapowaz", "zubbles", "sockeye"]
    developers.include?(lower_name)
  end

  def complete_login(connection)
    old_id = @id
    @id = connection.id
    @total_connections = @total_connections + 1
    @last_activity = @last_login = Time.now
    @ip_address = connection.ip_address
    @muffled = false
    
    
    if resident?
      output box("Recent Changes", get_text("changes"))
    else
      output get_text("welcome_newuser")
    end

    old_connection = connections[old_id]

    if old_connection.nil?
      connected_users[lower_name] = self
      output_to_all "^g\u{00bb} ^n#{name} #{get_connect_message} ^g\u{00ab}^n"
    else
      old_connection.output "[Reconnection from #{connection.ip_address}]"
      old_connection.disconnect
      output_to_all "^y\u{00bb} ^n#{name} #{get_reconnect_message} ^y\u{00ab}^n"
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
    output_to_all "^r\u{00ab} ^n#{name} #{get_disconnect_message} ^r\u{00bb}^n"
    
    if !resident?
      delete
    else
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
    @prompt || "Dragon> "
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
    @timezone_identifier || Talker::TIMEZONE
  end
  
  def get_connect_message
    @connect_message || "enteres thy realme"
  end

  def get_disconnect_message
    @disconnect_message || "leaves thy realme"
  end

  def get_reconnect_message
    @reconnect_message || "rejoins they realme"
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
      output_to_all "^R\u{2192}^n Anti-cheese code detected a violation by #{name}"
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
    "#{RANK_COLOUR[rank]}#{RANK[rank]}^n"
  end

  def cname
    "#{RANK_COLOUR[rank]}#{name}^n"
  end
  
  def examine
    buffer = "       First seen : #{get_timezone.strftime("%l:%M %p, %A %d %B %Y", first_seen).strip}\n"
    if logged_in?
      buffer += "       Login time : #{time_in_words(login_time)}\n"
      buffer += "        Idle time : #{time_in_words(idle_time)}\n"
      buffer += " Total login time : #{time_in_words(total_time + login_time)}\n"
    else
      buffer += " Total login time : #{time_in_words(total_time)}\n"
    end
    buffer += "      Connections : #{total_connections}\n"
    buffer += "             Rank : #{rank_name_with_colour}\n"
    buffer += "        Real name : #{realname}^n\n" unless realname.blank?
    
    gender_symbol = case gender
      when :male then "\u{2642}"
      when :female then "\u{2640}"
      else "None"
    end
    
    buffer += "           Gender : #{gender_symbol}\n"
    buffer += "           Drogna : #{commify(money)}\u{20ab}\n"
    buffer += "   Marital Status : #{maritalstatus.capitalize}^n\n" unless maritalstatus.blank?
    buffer += "         Location : #{location}^n\n" unless location.blank?
#    buffer += "     Zone of Tyme : #{get_timezone_identifier.gsub(/_/, ' ')}^n\n" unless get_timezone_identifier == "Europe/London"
    buffer += "       Occupation : #{occupation}^n\n" unless occupation.blank?
    buffer += "         Homepage : ^U^B#{homepage}^n\n" unless homepage.blank?
    buffer
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
