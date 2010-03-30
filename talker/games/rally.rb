# encoding: utf-8

class Rally
  include TalkerUtilities
  attr_accessor :stage, :vehicle, :seatbelt, :engine_started, :handbrake_released
  attr_reader :turn_time, :stage_records, :best_total_time
  
  SPEED = {
    'chopper' => 1,
    'minibus' => 2,
    'lada'    => 3,
    'subaru'  => 4,
    'skoda'   => 4,
    'ford'    => 4,
    'citroen' => 5,
    'ferrari' => 6,
    'reference' => 5
  }

  TRACTION = {
    'chopper' => 2,
    'minibus' => 1,
    'lada'    => 3,
    'subaru'  => 4,
    'skoda'   => 3,
    'ford'    => 5,
    'citroen' => 4,
    'ferrari' => -10,
    'reference' => 5
  }
  
  def initialize
    @best_total_time = 1000000.0
    @stage_records = []
    restart
  end

  def next_stage
    @stage += 1
  end
  
  def start_stage
    @corner = 0
    @total_time = 0
    @earnings = 0
    next_corner
  end
  
  def restart
    @stage = 1
    @corner = 0
    @total_rally_time = 0.0
  end
  
  def next_corner
    srand(1234 + (@stage * 100) + @corner)
    @turn_time = (((rand(50) / 10.0) + 0.5) * (1.0 + (0.2 * (5 - Rally::SPEED[@vehicle])))).round(1)
    @direction = rand(2) == 0 ? :left : :right
    @sharp = rand(2) == 0
    @swerve = rand(25) == 13
    @turn_time = 0 if @swerve
    @corner += 1
    @last_time = Time.now
    srand(Time.now.to_i)
    @object = OBJECTS[rand(OBJECTS.length)] if @swerve
  end
  
  def stage_finished?
    @corner == 0 || @corner > 18
  end
  
  OBJECTS = ['moose', 'dog', 'cat', 'pot hole', 'bear']
  
  def instructions
    message = if @swerve
      "Look out, there is a #{@object} in the road!"
    else
      "Turn#{@sharp ? ' sharply' : ''} #{@direction} in #{@turn_time} seconds."
    end
    "^L> Navigator tells you \u{2018}#{message}\u{2019}^n"
  end

  def turn_result(time_diff)
    if time_diff == 0
      "^GPERFECT TURN"
    elsif time_diff.abs < 0.5
      "^gGood turn"
    else
      earlylate = time_diff > 0 ? "late" : "early"
      t = time_diff.abs
      amount = if t < 1.0
        "^ySlightly"
      elsif t < 1.5
        "^YConsiderably"
      elsif t < 2.0
        "^rSignificantly"
      else
        "^RExtremely"
      end
      "^R#{amount} #{earlylate}"
    end
  end
  
  def time_penalty(time_diff)
    time_diff.abs * (2.0 + (((5.0 - Rally::TRACTION[@vehicle]) * 0.2)))
  end
  
  def turn(user, type, direction=nil)
    duration = Time.now - @last_time
    time_diff = (duration - @turn_time).round(1)
    if type == :swerve && @swerve && time_diff < 6.0
      @total_time += (@turn_time + time_penalty(time_diff)).round(1)
      user.output "[#{minutes_seconds(@total_time.round(1))}] You missed the #{@object} ^n#{time_diff}s"
    elsif (direction == @direction && ((!@sharp && type == :normal) || (@sharp && type == :handbrake))) && time_diff.abs < 6.0
      @total_time += (@turn_time + time_penalty(time_diff)).round(1)
      time_string = time_diff == 0.0 ? "" : "(#{time_diff.abs}s #{time_diff < 0.0 ? 'early' : 'late'})" 
      user.output "[#{minutes_seconds(@total_time.round(1))}] #{turn_result(time_diff)} ^n#{time_string}"
    else
#      damage = stage_records.empty? ? 0 : ((20 + rand(130)) ** (1.0 + Rally::SPEED[@vehicle]/10.0)).floor
      damage = 0
      item = user.items.find(@vehicle)
      if item && !stage_records.empty?
        damage = (((75 + rand(50)) / 1000.0) * item.price).floor
        item.damage += damage
      end
      damage_string = ""
      damage_string = ", causing #{currency(damage)} of damage to #{user.hisher} #{@vehicle}" if damage > 0
      user.output_to_all "^R\u{2192}^n #{user.name} crashed out of stage #{@stage} of the rally#{@swerve ? ', hitting a ' + @object : ''}#{damage_string}!"
      restart
    end
    if !stage_finished?
      next_corner
      if stage_finished?
        best_string = ""
        if !@stage_records[@stage-1] || @total_time < @stage_records[@stage-1]
          best_string = " ^L(personal best)^n"
          best_string = " ^G(stage record)^n" if Rally.record_stage_time?(@stage, @total_time)
          @stage_records[@stage-1] = @total_time
        end
        @total_rally_time += @total_time
        winnings = (10000 * ((Rally::stage_reference_time(@stage) / @total_time) ** 5)).round
        
        user.output_to_all "^G\u{2192}^n #{user.name} completed Rally Stage #{@stage} in #{minutes_seconds(@total_time)}, winning #{currency(winnings)}!#{best_string}"
        user.money += winnings
        if @stage == 20
          winnings = (100000 * ((Rally::REFERENCE_TIME / @total_rally_time) ** 4)).round
          user.money += winnings
          best_string = ""
          if @total_rally_time < @best_total_time
            best_string = " ^L(personal best)^n"
            best_string = " ^G(world record)^n" if Rally.rally_record_time?(@total_rally_time)
            @best_total_time = @total_rally_time
          end
          user.output_to_all "^G\u{2192}^n #{user.name} completed the rally in #{minutes_seconds(@total_rally_time)}, winning #{currency(winnings)}!#{best_string}"
          restart
        else
          next_stage
        end
        user.save
      else
        user.output instructions
      end
    end
  end

  STAGE_REFERENCE_TIMES = [47.1, 51.0, 53.8, 44.4, 49.2, 49.8, 45.6, 48.4, 49.9, 56.3, 62.7, 55.8, 52.1, 48.1, 53.4, 46.8, 38.7, 58.1, 62.8, 55.4]
  REFERENCE_TIME = 1029.4

  def self.stage_reference_time(stage)
    Rally::STAGE_REFERENCE_TIMES[stage - 1]
  end

  def self.calculate_stage_reference_time(stage)
    r = Rally.new
    r.vehicle = 'reference'
    r.stage = stage
    r.start_stage
    total = 0.0
    while !r.stage_finished?
      total += r.turn_time
      r.next_corner
    end
    total
  end

  def self.user_stage_times(stage)
    Talker.instance.all_users.values.select{|u| u.rally && !u.rally.stage_records[stage-1].nil?}.sort {|a,b| a.rally.stage_records[stage-1] <=> b.rally.stage_records[stage-1]}
  end
  
  def self.stage_record(stage)
    u = self.user_stage_times(stage).first
    u ? u.rally.stage_records[stage - 1] : 1000000.0
  end
  
  def self.record_stage_time?(stage, time)
    time < self.stage_record(stage)
  end

  def self.user_total_times
    Talker.instance.all_users.values.select{|u| u.rally && u.rally.best_total_time < 1000000.0}.sort {|a,b| a.rally.best_total_time <=> b.rally.best_total_time}
  end
  
  def self.rally_record
    u = user_total_times.first
    u ? u.rally.best_total_time : 1000000.0
  end

  def self.rally_record_time?(time)
    time < self.rally_record
  end

end

module Commands
  define_command 'forecourt' do
    output box("Motor Despot Honeste Used Cars", ['chopper', 'minibus', 'lada', 'subaru', 'skoda', 'ford', 'citroen', 'ferrari' ].map {|item_name| item = Items::ITEMS[item_name]; "^c#{sprintf("%10s", currency(item.price))}^n^L #{sprintf("%-7s", item.name)}^n  #{item.description}"}.join("\n"))    
  end
  
  define_command 'rally' do
#    debug_message "#{(1..20).map {|i|Rally.calculate_stage_reference_time(i)}}"
    if rally
      if !rally.stage_finished?
        output "You are currently on stage #{rally.stage} of the rally. Type ^Lhelp rally^n for assistance."
      else
        output "Type ^Lrally start^n to begin stage #{rally.stage}. Type ^Lhelp rally^n for assistance."
      end
    else
      output "Type ^Lrally start^n to begin the first stage of the rally. Type ^Lhelp rally^n for assistance."
    end
  end
  
  define_command 'rally start' do
    self.rally ||= Rally.new
    if rally.vehicle.nil? || !(vehicle = items.find(rally.vehicle))
      output "You need to ^Lsit in^n a vehicle first. If you don't own a vehicle, you can ^Lbuy^n one from the ^Lforecourt^n."
    elsif vehicle.damage > 0.0
      output "Your #{rally.vehicle} requires #{currency(vehicle.damage)} of repairs before you can use it again."
    elsif !rally.seatbelt
      output "Rallying is dangerous! ^Lfasten seatbelt^n first!"
    elsif !rally.engine_started
      output "^Lturn key^n to start start the engine!"
    elsif !rally.handbrake_released
      output "^Lhandbrake release^n to proceed!"
    else
      rally.start_stage
      output "^nYou start the rally in your #{rally.vehicle}. Type ^Lhelp rally^n for assistance.\n^G== Rally Stage #{rally.stage} ==^n\n#{rally.instructions}"
#      debug_message Rally::stage_reference_time(rally.stage)
    end
  end
  
  define_command 'rally times' do |target_name|
    target = target_name.blank? ? self : find_user(target_name)
    if !target
      output "Format: rally times <user name>"
    elsif !target.rally || target.rally.stage_records.empty?
      output "#{target.name} doesn't have any rally times."
    else
      count = 0
      record_lines = target.rally.stage_records.map {|rec| 
        count = count + 1
        stage_rec = Rally.stage_record(count)
        best_string = if rec == stage_rec
          "^G(stage record)^n"
        else
          "(#{minutes_seconds(rec - stage_rec)} off the stage record)"
        end
        "^cStage #{sprintf("%02d", count)}.^n^L #{minutes_seconds(rec)}^n #{best_string}"
      }.join("\n")
      total_time_line = target.rally.best_total_time < 1000000 ? "\nBest overall rally time: #{minutes_seconds(target.rally.best_total_time)}" : ""
      
      output box("#{target.name} Best Times", "#{record_lines}#{total_time_line}")
    end
  end
    
  define_command 'sit in' do |item_name|
    if item_name.blank?
      output "Format: sit in <item name>"
    else
      item = items.find(item_name)
      if item.nil?
        output "You don't have a #{item_name}. Type ^Linventory^n to see what you have."
      elsif ['Chopper', 'Minibus', 'Lada', 'Subaru', 'Skoda', 'Ford', 'Citroen', 'Ferrari'].include?(item.name)
        self.rally ||= Rally.new
        rally.vehicle = item.name.downcase
        rally.seatbelt = false
        rally.engine_started = false
        rally.handbrake_released = false
        output "You have entered your #{item.name}."
      else
      end
    end
  end
  
  define_command 'sit' do |text|
    if text.blank?
      if rally && rally.vehicle
        output "You are currently sitting in your #{rally.vehicle}"
      else
        output "Format: sit in <vehicle name>"
      end
    else
      output "Format: sit in <vehicle name>"
    end
  end
  
  define_command 'fasten seatbelt' do
    self.rally ||= Rally.new
    if !rally.vehicle
      output "You are not in a vehicle!"
    else
      rally.seatbelt = true
      output "You have fastened your seatbelt."
    end
  end

  define_command 'rally quit' do
    self.rally ||= Rally.new
    rally.restart
    output "You have quit the rally."
  end

#  define_command 'rally reset' do
#    all_users.values.each {|u| u.rally = nil; u.save}
#  end
  
  define_command 'turn' do |direction|
    if rally.nil? || rally.stage_finished?
      output "You are not currently running in a rally, type ^Lrally start^n to begin."
    elsif !["left", "right"].include?(direction)
      output "Format: turn <left|right>"
    else
      rally.turn(self, :normal, direction.to_sym)
    end
  end

  define_command 'swerve' do
    if rally.nil? || rally.stage_finished?
      output "You are not currently running in a rally, type ^Lrally start^n to begin."
    else
      rally.turn(self, :swerve)
    end
  end

  define_command 'handbrake' do |direction|
    if rally.nil? || rally.stage_finished?
      output "You are not currently running in a rally, type ^Lrally start^n to begin."
    elsif !["left", "right"].include?(direction)
      output "Format: handbrake <left|right>"
    else
      rally.turn(self, :handbrake, direction.to_sym)
    end
  end

  define_command 'handbrake release' do
    self.rally ||= Rally.new
    if !rally.vehicle
      output "You are not in a vehicle!"
    else
      rally.handbrake_released = true
      output "You have released the handbrake."
    end
  end

  define_command 'turn key' do
    self.rally ||= Rally.new
    if !rally.vehicle
      output "You are not in a vehicle!"
    else
      rally.engine_started = true
      output "You have started your engine."
    end
  end

  define_command 'help rally' do
    output box("RAC Roadside Assistance", "First you will need a car. Type ^Lforecourt^n to view the available vehicles
and ^Lbuy <vehicle>^n to purchase one. Once you have a vehicle type 
^Lsit in <vehicle>^n to occupy it. You will then need to get the car started,
to do that type ^Lrally start^n and follow the instructions given.

Once the rally has started you must listen very carefully to the navigators 
instructions and respond appropriately. The car controls are:
^Lturn left^n       - For normal left corners
^Lhandbrake left^n  - For sharp left corners
^Lhandbrake right^n - For sharp right corners
^Lturn right^n      - For normal right corners
^Lswerve^n          - To avoid obstacles in the road

The object of the game is to complete all 20 stages in the best time 
possible. If you crash you have to repair your vehicle and start again 
from stage 1. Type ^Lrepair <vehicle>^n to fix it. If you are unable to 
complete a stage, type ^Lrally quit^n to avoid a crash.

Type ^Lrally times^n to view your stage times.
")
  end
end