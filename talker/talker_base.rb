# encoding: utf-8
require 'singleton'
require 'open-uri'

require 'talker/talker'

require 'talker/util'
require 'talker/helpers'

require 'talker/connection'
require 'talker/user'
require 'talker/textfile'
require 'talker/history'

require 'talker/lastfm_ext'

require 'talker/multis'
require 'talker/commands'
require 'talker/socials'
require 'talker/memos'
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
require 'talker/games/connectfour'
require 'talker/games/othello'
require 'talker/games/quiz'
require 'talker/games/rally'
require 'talker/games/conkers'

class TalkerBase
  NAME    = 'Dockyard'
  VERSION = `cat .git/refs/heads/master`.chomp
  TIMEZONE = 'Europe/London'
  
  LIVE = File.exist?('LIVE')
  
  include Singleton
  
  attr_accessor :connected_users, :all_users, :output, :connections, :channels,
                :talk_server_uptime, :connection_server_uptime, :shutdown, :weather
  attr_reader :current_id
  
  def initialize
    @connections = {}
    @all_users = {}
    @connected_users = {}
    @commands = {}
    @connection_server_uptime = nil
    @talk_server_uptime = Time.now
    @shutdown = false
    @attributes = {}
    @channels = {}
    @weather = nil
  end
  
  def run
    @output = EM::Channel.new
    Textfile.load
    @all_users = User.load_all
    Social.import_all
    Game.load
    Fishing.load
    
    load_connections
    load_attributes
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

  def save_attributes
    f = File.new("data/talker.yml", "w")
    f.puts YAML.dump(@attributes)
    f.close
  end

  def save
    $stderr.puts "#{Time.now} [saving]"
    save_connections
    save_connected_users
    save_attributes
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

  def load_attributes
    if FileTest.exist?("data/talker.yml") 
      f = File.new("data/talker.yml", "r")
      @attributes = YAML.load(f.read)
      f.close
    end
    @attributes[:history] ||= History.new
    @attributes[:on_fire] ||= Hash.new
    @attributes[:conkers_on_ground] ||= 8
    @attributes[:sticks_on_ground] ||= 2
  end

  def set_attribute(name, value)
    @attributes[name] = value
  end

  def debug_message(message)
    @connected_users.values.select {|u|u.debug}.each { |u| u.output "^g[debug] #{message}^n" }
  end  
  
  def dev_message(message)
    @connected_users.values.select {|u|u.lower_name == 'thebear'}.each { |u| u.output "^G[dev] #{message}^n" }
  end
  
  def method_missing(method_sym, *arguments, &block)
    if @attributes.has_key?(method_sym)
      @attributes[method_sym]
    else
      super
    end
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
    EventMachine::add_timer time_to_wait, proc { TalkerBase.instance.tick(@next_tick) }
  end
  
  def tick(now)
    if (now.to_i % 120) == 0 # every 2 minutes
      @connected_users.each do |name, u|
        u.raw_send "\377\361" # send IAC NOP

        if u.alcohol_units > 0
          if u.alcohol_units > 25
            amount = 30 - (u.alcohol_units - 25)
            amount = 3 if amount < 3
            r = rand(amount)
            if r == 0
              u.output_to_all u.vomit_string("\u{2192} #{u.name} vomits all over #{u.gender == :male ? 'him' : 'her'}self!")
              u.alcohol_units = (u.alcohol_units - 8).round
            elsif r == 1
              u.output_to_all "#{u.cname} flails their fists in the air like a ^r*^cm^Ru^cp^Rp^ce^Rt^r*!^n"
            elsif r == 2
              u.output_to_all "#{u.cname} ^Yhas wet  #{u.gender == :male ? 'his' : 'her'} pants^n"
            else
              u.alcohol_units -= 2
            end
          elsif (Time.now - u.last_drink) > 900 # 15 minutes
            u.alcohol_units -= 2
            if u.alcohol_units > 0
              u.output "You are sobering up."
            else
              u.alcohol_units = 0
              u.output "You feel completely sober."
            end
          end
        end

      end
    end

    if (now.to_i % 300) == 0 # every 5 minutes
      Social.issue_payments
    end
    
    if (now.to_i % 900) == 0 # every 15 minutes
      @connected_users.each do |name, u|
        if u.active?
          amount = 30 * (u.rank + 1)
          u.money += amount
        end
      end
      save

      @attributes[:conkers_on_ground] += (rand(3) + 1) if @attributes[:conkers_on_ground] < 8
      @attributes[:sticks_on_ground] += rand(2) if @attributes[:sticks_on_ground] < 1
    end
    
    @connected_users.each do |name, u|
      if u.active?
        u.fishing.tick(u) if u.fishing
        u.community_service.tick(u) if u.community_service
        
        if u.tripping && u.tripping < now
          u.tripping = nil
          u.drug_strength = 0
          u.output "^nYou feel better now."
        end
        
        if u.brummed && u.brummed < now
          u.brummed = nil
          u.output "^nYou speak English again."
        end

        if u.wossed && u.wossed < now
          u.wossed = nil
          u.output "^nYou speak English again."
        end
        
        if u.prison && (now - u.prison > 120)
          u.release_from_prison
        end

        if u.on_phone
          if u.money > 100
            u.money -= 100
          else
            u.money = 0
            target = u.find_connected_user(u.on_phone, :silent => true)
            target.output "The phone line to #{u.name} has gone dead." if target
            u.on_phone = nil
            u.output "Your call has ended because you have run out of money."
          end
        end
      end
    end

    if !@attributes[:on_fire].empty?
      grow_fire
      @connected_users.each do |name, u|
        u.output "^R\u{2192}^n Thy realm is on fire! #{@attributes[:on_fire].length} commands are burning!"
      end
    end
    schedule_tick
  end
  
  def start_fire
    10.times {grow_fire}
  end
  
  def grow_fire
    new_fire = Talker.command_names[rand(Talker.command_names.length)]
    @attributes[:on_fire][new_fire] = true unless new_fire == "hose"
  end
end
