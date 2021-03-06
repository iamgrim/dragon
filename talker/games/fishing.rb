class Fish
  attr_accessor :name
  
  def initialize(name, bait, average_size)
    @name = name
    @bait = bait
    @average_size = average_size
  end
  
  def eats_bait?(bait_number)
    @bait[bait_number] > 0
  end
  
  def get_size
    size = (@average_size * (rand ** 1.5)).round(3)
    size = 0.001 if size == 0.0
    return size
  end
  
  def fish_class(size)
    (size / (@average_size / 3.0)).floor + 1
  end
end

class Fishing
  VENDING_MACHINE = Items.new([
    Item.new("Maggots", "~ ~ ~", 10, 50),  # 5
    Item.new("Castors", "", 10, 100),      # 10
    Item.new("Worms", "", 10, 120),        # 12
    Item.new("Bread", "", 10, 90),         # 9
    Item.new("Boilies", "", 14, 336),      # 24
    Item.new("Sweetcorn", "", 9, 171),     # 19
    Item.new("Luncheon Meat", "", 12, 840) # 70
  ])
  
  BAIT_TYPES = {
    "Maggots"       => 0,
    "Castors"       => 1,
    "Worms"         => 2,
    "Bread"         => 3,
    "Boilies"       => 4,
    "Sweetcorn"     => 5,
    "Luncheon Meat" => 6
  }
  
  FISH = [
    Fish.new("Gudgeon"      , [1,0,0,0,0,0,0], 1),
    Fish.new("Dace"         , [1,1,0,0,0,0,0], 3),
    Fish.new("Roach"        , [1,1,0,0,0,0,0], 6),
    Fish.new("Rudd"         , [1,1,0,1,0,0,0], 6),
    Fish.new("Perch"        , [1,0,1,0,0,0,0], 8),
    Fish.new("Crucian Carp" , [1,0,0,0,1,0,0], 10),
    Fish.new("Grayling"     , [1,1,1,0,0,0,0], 16),
    Fish.new("Chub"         , [1,1,1,1,0,1,1], 48),  # 3lb
    Fish.new("Eel"          , [1,0,1,0,0,0,1], 64),  # 4lb
    Fish.new("Tench"        , [0,1,1,0,0,1,1], 80),  # 5lb
    Fish.new("Barbel"       , [0,0,1,0,0,1,1], 80),  # 5lb
    Fish.new("Bream"        , [0,0,0,1,0,0,0], 88),  # 5.5lb
    Fish.new("Common Carp"  , [0,0,0,0,1,0,0], 160), # 10lb
    Fish.new("Zander"       , [0,0,0,0,0,0,1], 192), # 12lb
    Fish.new("Pike"         , [0,0,0,0,0,0,1], 304), # 19lb
    Fish.new("Catfish"      , [0,0,0,0,0,0,1], 328)  # 20.5lb
  ]

  @world_records = {}

  attr_accessor :cast, :bait, :bite, :reeling, :catch_size, :subscribed
  attr_reader :fish
  
  def initialize
    @cast = false
    @bite = 0
    @misses = 0
    @bait = nil
  end
  
  def baitbox()
    @baitbox ||= Items.new
  end
  
  def records
    @records ||= Hash.new
  end
  
  def set_record?
    if !records.has_key?(@fish.name) || records[@fish.name] < @catch_size
      records[@fish.name] = @catch_size
    end
  end
  
  def combined_catch_total
    @records ? @records.values.inject(0) {|a, b| a + b} : 0
  end
  
  def self.set_world_record?(user)
    fish = user.fishing.fish.name
    size = user.fishing.catch_size
    if !@world_records.has_key?(fish) || @world_records[fish][1] < size
      @world_records[fish] = [user.name, size]
    end
  end
  
  def self.world_records
    @world_records
  end
  
  def reel_in
    @cast = false
    @misses = 0
    @bite = 0
    @reeling = nil
  end
  
  def self.find_fish_by_name(name)
    result = Fishing::FISH.select {|f| f.name == name}
    result.empty? ? nil : result.first
  end
  
  def get_fish(bait_name)
    possible_fish = Fishing::FISH.select {|fish| fish.eats_bait?(BAIT_TYPES[@bait])}
    possible_fish.empty? ? nil : possible_fish[rand(possible_fish.length)]
  end
  
  BITE_STRING = [
    "The float is still",
    "The float moved slightly",
    "The float moved significantly",
    "The float has disappeared and the reel is unwinding",
    "The reel is still unwinding"
  ]
  
  def tick(user)
    unless @reeling
      if @bite > 0
        @bite += rand(2) # 50% chance of bite developing
        @bite = 0 if rand(3) == 0 # 33% chance of bite leaving
        @bite = 4 if @bite > 4
        user.output "^c[#{BITE_STRING[@bite]}]^n"
        if @bite == 0
#          user.debug_message "#{user.name} miss"
          @misses += 1
          if @misses > 5
            reel_in
            user.output "Your arms got tired so you had to reel in your fishing rod."
          end
        end
      else
        if @cast
          r = rand(3) # was 6
#          user.debug_message "#{user.name} #{r} #{@misses}"
          if r == 0
            @fish = get_fish(@bait)
#            user.debug_message "#{user.name} #{@fish.name}"
            if @fish
              @bite = rand(3) + 1
              user.output "^c[#{BITE_STRING[@bite]}]^n"
            end
          end
        end
      end
    end
  end
  
  def self.rankings
    TalkerBase.instance.all_users.values.select{|u|u.fishing}.sort{|u,u2|u2.fishing.combined_catch_total <=> u.fishing.combined_catch_total}
  end
  
  def self.ranking(user)
    rankings.index(user) + 1
  end
  
  def self.pounds_oz(amount)
    pounds = (amount / 16.0).floor
    oz = (amount % 16.0).round(3)
    [pounds > 0 ? "#{pounds}lb" : nil, oz > 0.0 ? "#{oz}oz" : nil].compact.join(" ")
  end
  
  def self.save
    f = File.new("data/fishing.yml", "w")
    f.puts YAML.dump(@world_records)
    f.close
  end
  
  def self.load
    if FileTest.exist?("data/fishing.yml") 
      f = File.new("data/fishing.yml", "r")
      @world_records = YAML.load(f.read)
      f.close
    end
  end
end

module Talker

  define_command 'fishing bait' do |bait_name|
    self.fishing ||= Fishing.new

    if bait_name.blank?
      if fishing.bait.blank?
        output "You haven't selected a bait. Select one by typing ^Lfishing bait <bait name>^n"
      else
        output "You are fishing with #{fishing.bait}. To change bait type ^Lfishing bait <bait name>^n"
      end
    else
      if bait = fishing.baitbox.find(bait_name)
        fishing.bait = bait.name
        output "You are fishing with #{bait.name}. Your supply will be depleted when you cast."
        save
      else
        output "You don't have any #{bait_name}. Type ^Lfishing baitbox^n to view your available bait."
      end
    end
  end

  define_command 'fishing cast' do
    self.fishing ||= Fishing.new
    if !fishing.bait
      output "You won't catch anything without selecting a bait!"
    elsif !fishing.cast
      if bait = fishing.baitbox.find(fishing.bait)
        result = rand(20)
        if result < 12 # 0 1 2 3 4 5 6 7 8 9 10 11
          fishing.baitbox.deplete(bait.name)
          fishing.cast = true
          output "You cast successfully. (#{bait.quantity} #{bait.name} left)"
        elsif result < 14 # 12 13
          output "You messed up the cast completely! Adjust your grip and try again."
        elsif result < 16 # 14 15
          output "You cast into the weeds and your line got tangled. Try again."
        elsif result < 18 # 16 17
          output "You failed to cast. Loosen your wrist and try again."        
        elsif result < 19 # 18
          if rand(250) == 125 # 1 in 5000 chance (1/20 * 1/250)
            output "You failed to cast because the line got caught on a pylon and ^Rstarted a fire!^n"
            TalkerBase.instance.start_fire
          else
            output "You failed to cast because the line got caught on a pylon. Please try again."
          end
        else # 19
          fishing.baitbox.deplete(bait.name)
          fishing.cast = false
          buffer = case rand(4)
          when 0 then "The line snapped and your bait floated away!"
          when 1 then "You dropped your bait and a rat stole it!"
          when 2 then "You dropped your bait and a cat stole it!"
          else        "A bird stole your bait before you could cast!"
          end
          output "#{buffer} (#{bait.quantity} #{bait.name} left)"
        end
        save
      else
        output "You have run out of #{fishing.bait}. Vend more or choose a different bait."
      end
    else
      output "You have already cast successfully."
    end
  end

  define_command 'fishing reel' do
    if fishing.nil? || !fishing.cast
      output "You are not currently fishing."
    elsif fishing.bite == 0
      fishing.reel_in
      output "You reel your line in."
    elsif !fishing.reeling
      r = rand(1 + fishing.bite)
      if r > 0
        fishing.catch_size = fishing.fish.get_size
        fishing.reeling = true
      else
        fishing.reel_in
        output "You reel in your line, but there is nothing on the hook."
      end
    end
    
    if fishing.reeling
      r = rand(3 + (fishing.catch_size / 32))
#      debug_message "#{name} Reeling fish in class #{fishing.fish.fish_class(fishing.catch_size)} / #{r}"
      if r < 2 # 0 1
        if rand(8000) == 4000
          winnings = 100000
          output_to_all "^C><>^n #{name} caught a ^LShopping Trolley^n worth #{currency(winnings)}!"
        else
          winnings = (fishing.catch_size * 16).round
#          winnings = winnings * 10 if (fishing.fish.name == "Pike")
          best_string = ""
          best_string = " Laugh at the state of them!" if winnings == 0
          best_string = " ^L(personal best)^n" if personal_best = fishing.set_record?
          best_string = " ^G(world record)^n" if Fishing.set_world_record?(self)
          
          buffer = "^C><>^n #{name} caught a #{Fishing::pounds_oz(fishing.catch_size)} ^L#{fishing.fish.name}^n worth #{currency(winnings)}!#{best_string}^n"
          if personal_best
            output_to_all buffer
          else
            output_to_some(buffer) {|u| (u.fishing && u.fishing.subscribed) || u == self}
          end
        end
        self.money += winnings
        fishing.reel_in
      elsif r < 3 # 2
        fishing.reel_in
        output "You reel in your line, but the fish has escaped!"
      else
        if rand(10) == 0
          output "This fish is really obstreperous. Try again."
        else
          output "Something is pulling on the line and you were unable to reel it in. Try again."
        end
      end
    end
    save
  end

  define_command 'fishing baitbox' do |target_name|
    target = target_name.blank? ? self : find_user(target_name)
    if !target
      output "Format: fishing baitbox <user name>"
    elsif !target.fishing || target.fishing.baitbox.empty?
      output "#{target.name} has nothing in their baitbox."
    else
      output box("#{target.name} Baitbox", target.fishing.baitbox.to_s)
    end
  end

  define_command 'fishing records' do |target_name|
    target = target_name.blank? ? self : find_user(target_name)
    if !target
      output "Format: fishing records <user name>"
    elsif !target.fishing || target.fishing.records.empty?
      output "#{target.name} doesn't have any fishing records."
    else
      output box("#{target.name} Fishing Records", target.fishing.records.sort{|a,b|a[0] <=> b[0]}.map {|name, weight| 
        f = Fishing.find_fish_by_name(name)
        if f
          (user_name, record) = Fishing.world_records[name]
          best_string = if user_name.nil?
            ""
          elsif user_name.downcase == target.lower_name
            "^GWR^n"
          else
            "(#{Fishing.pounds_oz(record - weight)} below the world record)"
          end
          " ^c#{f.fish_class(weight)}^n ^L#{sprintf("%14.14s", name)}^n ^L#{Fishing::pounds_oz(weight)}^n #{best_string}"
        else
          nil
        end
        }.compact.join("\n"))
    end
  end
  
  define_command 'fishing worldrecords' do
    output box("Fishing World Records", Fishing.world_records.sort{|a,b|a[0] <=> b[0]}.map { |name, value|
      (user_name, weight) = value
      " #{sprintf("%-15.15s", name)}^n #{sprintf("%-15.15s", user_name)} #{Fishing::pounds_oz(weight)}^n"
      }.join("\n"))
  end
  
  define_command 'fishing quit' do
    fishing.reel_in if fishing
    output "You have packed away your fishing equipment."
  end

  define_command 'fishing subscribe' do
    self.fishing ||= Fishing.new
    if fishing.subscribed
      output "You are already subscribed to Angling Times."
    else
      fishing.subscribed = true
      save
      output "You are now subscribed to Angling Times."      
    end
  end

  define_command 'fishing unsubscribe' do
    self.fishing ||= Fishing.new
    if fishing.subscribed
      fishing.subscribed = false
      save
      output "You have unsubscribed from Angling Times."
    else
      output "You are not subscribed to Angling Times."
    end
  end
  
  define_command 'fishing rankings' do |num|
    r = Fishing::rankings
    pos    = num.to_i
    start  = pos - 7
    max    = r.length - 15
    start  = max if start > max
    start  = 0 if start < 0
    result = Fishing::rankings.slice(start, 15)
    len    = result.map {|u|u.name.length}.max
    count  = start
    output box("Dragon World Fishing Rankings", result.map {|u| count += 1; "#{(pos == 0 && u == self) || pos == count ? '^L' : ''}#{sprintf("%2.d", count)}. #{sprintf("%-#{len}.#{len}s", u.name)} #{Fishing::pounds_oz(u.fishing.combined_catch_total)}"}.join("^n\n"))
  end

  define_command 'vend' do |item_name|
    if item_name.blank?
      output box("Welcome to Master Bait Vending Machine", Fishing::VENDING_MACHINE.map {|item| "^L#{sprintf("%5s", currency(item.price))}^n #{item.name} (#{item.quantity} #{pluralise("piece", item.quantity)})"}.join("\n"))
    elsif item_to_buy = Fishing::VENDING_MACHINE.find(item_name)
      if purchased_item = item_to_buy.purchase_by(self)
        self.fishing ||= Fishing.new
        self.fishing.baitbox.add(purchased_item)
        output_to_all "^Y\u{2192}^n #{name} vends #{purchased_item.name}"
        save
      else
        output "You can't afford to buy #{item_to_buy.name}. It costs #{currency(item_to_buy.price)} and you only have #{money}\u{20ab}."
      end
    else
      output "Unknown item '#{item_name}'. Type ^Lvend^n to view the items available."
    end
  end
  
  define_alias 'fishing', 'f'
end