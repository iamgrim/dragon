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
    (@average_size * (rand ** 1.5)).round(3)
  end
  
  def fish_class(size)
    (size / (@average_size / 3.0)).floor + 1
  end
end

class Fishing
  VENDING_MACHINE = Items.new([
    Item.new("Maggots", "~ ~ ~", 10, 100), # 10
    Item.new("Castors", "", 10, 110),      # 11
    Item.new("Worms", "", 10, 120),        # 12
    Item.new("Bread", "", 10, 100),        # 10
    Item.new("Boilies", "", 8, 192),       # 24
    Item.new("Sweetcorn", "", 9, 171),     # 19
    Item.new("Luncheon Meat", "", 6, 156)  # 26
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
    Fish.new("Bream"        , [0,1,1,1,0,2,0], 7),
    Fish.new("Perch"        , [1,0,1,0,0,0,0], 8),
    Fish.new("Crucian Carp" , [1,0,1,1,1,0,2], 10),
    Fish.new("Grayling"     , [1,1,1,0,0,0,0], 16),
    Fish.new("Chub"         , [1,1,1,1,0,1,1], 48),
    Fish.new("Tench"        , [1,0,1,0,0,2,0], 48),
    Fish.new("Barbel"       , [0,1,0,0,0,0,3], 64),
    Fish.new("Eel"          , [1,0,1,0,0,0,1], 64),
    Fish.new("Common Carp"  , [0,0,1,0,3,0,1], 160),
    Fish.new("Pike"         , [0,0,0,0,0,0,1], 128),
    Fish.new("Catfish"      , [0,0,0,0,0,0,1], 112),
    Fish.new("Zander"       , [0,0,0,0,0,0,1], 192)
  ]

  @world_records = {}

  attr_accessor :cast, :bait, :bite, :reeling, :catch_size
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
  
  def break_line
    @cast = false
    @bait = nil
  end
  
  def reel_in
    @cast = false
    @bait = nil
    @misses = 0
    @bite = 0
    @reeling = nil
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

module Commands

  define_command 'fishing bait' do |bait_name|
    self.fishing ||= Fishing.new

    if bait_name.blank?
      if fishing.bait.blank?
        output "You don't have any bait on your hook."
      else
        output "You have #{fishing.bait} on your hook."
      end
    else
      if bait = fishing.baitbox.find(bait_name)
        fishing.baitbox.deplete(bait_name)
        fishing.bait = bait.name
        output "You fasten #{bait.name} to your hook."
      else
        output "You don't have any #{bait_name}. Type ^Lfishing baitbox^n to view your available bait."
      end
    end
  end

  define_command 'fishing cast' do
    self.fishing ||= Fishing.new
  
    if !fishing.cast
      if !fishing.bait
        output "You need some bait on the hook before you can cast."
      else
        result = rand(10)
        if result < 4 # 0 1 2 3
          fishing.cast = true
          output "You cast successfully."
        elsif result < 6 # 4 5
          output "You messed up the cast completely! Adjust your grip and try again."
        elsif result < 8 # 6 7
          output "You failed to cast. Loosen your wrist and try again."        
        elsif result < 9 # 8
          output "You failed to cast because the line got caught on a pylon. Please try again."        
        else # 9
          fishing.break_line
          output "The line snapped and your bait floated away!"
        end
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
      r = rand(3 + fishing.fish.fish_class(fishing.catch_size)) # minimum 4
#      debug_message "#{name} Reeling fish in class #{fishing.fish.fish_class(fishing.catch_size)} / #{r}"
      if r < 2 # 0 1
        best_string = ""
        best_string = " ^L(personal best)^n" if fishing.set_record?
        best_string = " ^G(world record)^n" if Fishing.set_world_record?(self)
        winnings = (fishing.catch_size * 4).round
        self.money += winnings
        output_to_all "^C\u{25ba}^n #{cname} caught a #{Fishing::pounds_oz(fishing.catch_size)} ^L#{fishing.fish.name}^n winning #{winnings}\u{20ab}!#{best_string}"
        fishing.reel_in
        save
      elsif r < 3 # 2
        fishing.reel_in
        output "You reel in your line, but the fish has escaped!"
      else
        output "Something is pulling on the line and you were unable to reel it in. Try again."
      end
    end
  end

  define_command 'fishing baitbox' do |target_name|
    target = target_name.blank? ? self : find_user(target_name)
    if !target
      output "Format: fishing baitbox <user name>"
    elsif !target.fishing || target.fishing.baitbox.empty?
      output "#{target.name} has nothing in their baitbox."
    else
      output title_line("#{target.name} Baitbox") + "\n" + target.fishing.baitbox.to_s + "\n" + blank_line
    end
  end

  define_command 'fishing records' do |target_name|
    target = target_name.blank? ? self : find_user(target_name)
    if !target
      output "Format: fishing baitbox <username>"
    elsif !target.fishing || target.fishing.records.empty?
      output "#{target.name} doesn't have any fishing records."
    else
      output title_line("#{target.name} Fishing Records") + "\n" + target.fishing.records.sort{|a,b|a[0] <=> b[0]}.map {|name, weight| 
        "^L#{sprintf("%14.14s", name)}^n #{Fishing::pounds_oz(weight)}"}.join("\n") + "\n" + blank_line
    end
  end
  
  define_command 'fishing worldrecords' do
    output title_line("Fishing World Records") + "\n" + Fishing.world_records.sort{|a,b|a[0] <=> b[0]}.map { |name, value|
      (user_name, weight) = value
      " #{sprintf("%-15.15s", user_name)} #{sprintf("%-15.15s", name)}^n #{Fishing::pounds_oz(weight)}^n"
      }.join("\n") + "\n" + blank_line
  end
  
  define_command 'fishing quit' do
    fishing.reel_in if fishing
    output "You have packed away your fishing equipment."
  end

  define_command 'vend' do |item_name|
    if item_name.blank?
      output title_line("Welcome to Master Bait Vending Machine") + "\n" + Fishing::VENDING_MACHINE.map {|item| "^L#{sprintf("%4d", item.price)}\u{20ab}^n #{item.name} (#{item.quantity} #{pluralise("piece", item.quantity)})"}.join("\n") + "\n" + blank_line
    elsif item_to_buy = Fishing::VENDING_MACHINE.find(item_name)
      if purchased_item = item_to_buy.purchase_by(self)
        self.fishing ||= Fishing.new
        self.fishing.baitbox.add(purchased_item)
        output_to_all "^Y\u{25ba}^n #{cname} vends #{purchased_item.name}"
        save
      else
        output "You can't afford to buy #{item_to_buy.name}. It costs #{item_to_buy.price}\u{20ab} and you only have #{money}\u{20ab}."
      end
    else
      output "Unknown item '#{item_name}'. Type ^Lvend^n to view the items available."
    end
  end
  
  define_alias 'fishing', 'f'
end