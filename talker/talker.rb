# encoding: utf-8
require 'singleton'
require 'open-uri'

require 'talker/util'
require 'talker/helpers'

require 'talker/connection'
require 'talker/user'
require 'talker/textfile'
require 'talker/history'

require 'talker/multis'
require 'talker/commands'
require 'talker/socials'
require 'talker/commands/cmd_system'
require 'talker/commands/cmd_user'
require 'talker/commands/cmd_comms'
require 'talker/commands/cmd_staff'
require 'talker/commands/cmd_dev'

require 'talker/items'
require 'talker/games/game'
require 'talker/games/base'
require 'talker/games/bsheep'
require 'talker/games/fishing'

class Talker
  NAME    = 'Dragon World'
  VERSION = '0.7.2'
  
  include Singleton
  
  attr_accessor :connected_users, :all_users, :output, :connections,
                :talk_server_uptime, :connection_server_uptime, :shutdown,
                :history
  attr_reader :current_id
  
  def initialize
    @connections = {}
    @all_users = {}
    @connected_users = {}
    @commands = {}
    @connection_server_uptime = nil
    @talk_server_uptime = Time.now
    @shutdown = false
    @history = History.new
  end
  
  def run
    @output = EM::Channel.new
    Textfile.load
    @all_users = User.load_all
    Social.import_all
    Game.load
    Fishing.load
    
    load_connections
    load_history
    @connections.values.each do |c|
      if c.logged_in?
        u = find_or_add_user(c.user_name)
        @connected_users[u.lower_name] = u
      end
    end
    
    start_heartbeat
  end
  
  def connection(signature, ip_address)
    @connections[signature] = Connection.new(signature, ip_address)
    save
  end
  
  def disconnection(signature)
    c = @connections[signature]
    if c
      if c.logged_in? # login has finished
        u = @all_users[c.user_name.downcase]
        if u
          u.logout if u.id == c.id
          @all_users.delete(u.lower_name) if !u.resident?
        end
      end
      @connections.delete(signature)
      save
    end
  end
  
  def disconnect_all
    @connections = {}
    @connected_users = {}
    @all_users.each {|name, u| 
      if !u.resident?
        u.delete
      elsif !u.id.nil?
        u.id = nil
        u.save
      end
    }
    @all_users.delete_if {|name, u| !u.resident?}
    save
  end
  
  def input(signature, string)
    @current_id = signature
    string ||= ""
    c = @connections[signature]
    if c.nil?
      output << "#{signature} disconnect"
    else
      if !c.logged_in?
        c.handle_input(string)
        if c.logged_in? # login has finished
          u = find_or_add_user(c.user_name)
          u.complete_login(c)
        end
        save
      else
        u = @all_users[c.user_name.downcase]
        if u.nil?
          c.disconnect
        else
          u.handle_input(string)
        end
      end
    end
    @current_id = nil
    if @shutdown
      EM.next_tick { EM.stop_event_loop }
    end
  end
  
  def find_or_add_user(name)
    u = @all_users[name.downcase]
    if u.nil?
      u = User.new(name)
      @all_users[name.downcase] = u
    end
    u
  end
  
  def save_connections
    f = File.new("data/connections.yml", "w")
    f.puts YAML.dump(@connections)
    f.close
  end

  def save_connected_users
    @connected_users.values.each do |u|
      u.save
    end
  end

  def save_history
    f = File.new("data/history.yml", "w")
    f.puts YAML.dump(@history)
    f.close
  end

  def save
    $stderr.puts "#{Time.now} [saving]"
    save_connections
    save_connected_users
    save_history
    Game.save
    Fishing.save
  end

  def load_connections
    if FileTest.exist?("data/connections.yml") 
      f = File.new("data/connections.yml", "r")
      @connections = YAML.load(f.read)
      f.close
    else
      @connections = {}
    end
    $stderr.puts "#{Time.now} [loaded #{@connections.keys.length} connections]"
  end

  def load_history
    if FileTest.exist?("data/history.yml") 
      f = File.new("data/history.yml", "r")
      @history = YAML.load(f.read)
      f.close
    end
  end

  def debug_message(message)
    @connected_users.values.select {|u|u.debug}.each { |u| u.output "^g[debug] #{message}^n" }
  end  
  
  def start_heartbeat
    # make sure that the tick is executed on a time rounded to 10 seconds
    @next_tick = Time.at((Time.now.to_i / 10) * 10)
    schedule_tick
  end
  
  def schedule_tick
    @next_tick += 10.0
    now = Time.now
    time_to_wait = @next_tick - now
    EventMachine::add_timer time_to_wait, proc { Talker.instance.tick(@next_tick) }
  end
  
  def tick(now)
    if (now.to_i % 120) == 0 # every 2 minutes
      @connected_users.each do |name, u|
        u.raw_send "\377\361" # send IAC NOP
      end
    end
    
    if (now.to_i % 900) == 0 # every 15 minutes
      @connected_users.each do |name, u|
        if u.active?
          amount = 3 * (u.rank + 1)
          u.money += amount
        end
      end
      save
    end
    
    @connected_users.each do |name, u|
      if u.active?
        u.fishing.tick(u) if u.fishing
        u.community_service.tick(u) if u.community_service
      end
    end
        
    schedule_tick
  end
  
end
