class Item
  attr_accessor :name, :description, :quantity, :price, :unique
  attr_writer :damage

  def initialize(name, description, quantity, price, unique=false)
    @name = name
    @description = description
    @quantity = quantity
    @price = price
    @unique = unique
  end

  def damage
    @damage || 0.0
  end

  def purchase_by(user, discount = 0)
    purchase_price = price - discount
    if user.money >= purchase_price
      user.money -= purchase_price
      clone
    else
      nil
    end
  end
end

class Items < Array
  ITEMS = {
    'dice'    => Item.new("Dice", "A six sided die", 1, 150),
    'lsd'     => Item.new("LSD", "Lysergic acid diethylamide", 1, 50),
    'pcp'     => Item.new("PCP", "Phenylcyclohexylpiperidine", 1, 100),
    'soap'    => Item.new("Soap", "A surfactant cleaning compound, used for personal cleaning", 10, 200),
    'water'   => Item.new("Water", "44cl of Dragon Mineral filtered through a dragons beard", 1, 40),
    'half'    => Item.new("Half", "Dragon Ale half pint", 1, 50),
    'pint'    => Item.new("Pint", "Dragon Ale one pint", 1, 100),
    'staylar' => Item.new("Staylar", "Belgian premium beer (90 bottles) ^RSpecial Offer!^n", 90, 3600),
    'vodka'   => Item.new("Vodka", "Dragon brand 70cl (10 servings)", 10, 1500),
    'chopper' => Item.new("Chopper", "Raleigh Bicycle. Speed 1, Traction 2", 1, 1000),
    'minibus' => Item.new("Minibus", "Salvation Army Minibus. Speed 2, Traction 1", 1, 5000),
    'lada'    => Item.new("Lada", "Lada VTFS Rally car. Speed 3, Traction 3", 1, 20000),
    'subaru'  => Item.new("Subaru", "Subaru Impreza Rally car. Speed 3, Traction 4", 1, 50000),
    'skoda'   => Item.new("Skoda", "Skoda Fabia Rally car. Speed 4, Traction 3", 1, 125000),
    'ford'    => Item.new("Ford", "Ford Focus RS Rally car. Speed 4, Traction 5", 1, 225000),
    'citroen' => Item.new("Citroen", "Citroen C4 Rally car. Speed 5, Traction 4", 1, 350000),
    'licence' => Item.new("Licence", "Official Groo Sounding Licence",1,0),
    'scratchings' => Item.new("Scratchings", "Finest Black Country Pork Scratchings",10,50),
    'tissues'  => Item.new("Tissues", "A Box of Dragon Size Tissues (10 per box)", 10, 89),
    'conker'   => Item.new("Conker", "", 1, 0),
    'stick'    => Item.new("Stick", "", 1, 0)
  }

  def add(item)
    i = find(item.name)
    if i
      i.quantity += item.quantity
    else
      self << item
    end
  end
  
  def remove(item)
    self.delete_if{|i|i.name.downcase == item.name.downcase}
  end
  
  def find(item_name)
    result = self.select {|i| i.name.downcase =~ /^#{Regexp.escape(item_name.downcase)}/}
    result.empty? ? nil : result.first
  end
  
  def deplete(item_name)
    i = find(item_name)
    if i
      i.quantity -= 1
      remove(i) if i.quantity <= 0
    end
  end
  
  def to_s
    map {|i|"#{i.quantity} #{i.name}"}.join("\n")
  end
end

module Talker

  define_command 'inventory' do |target_name|
    target = target_name.blank? ? self : find_user(target_name)
    if !target
      output "Format: inventory <user name>"
    elsif target.items.empty?
      output "#{target.name} has nothing."
    else
      output title_line("#{target.name} Inventory") + "\n" + target.items.to_s + "\n" + blank_line
    end 
  end
  
  define_command 'buy' do |item_name|
    if item_name.blank?
      output box("Dragon Worlde Shope", ['dice', 'lsd', 'pcp', 'soap', 'water', 'half', 'pint', 'staylar', 'vodka', 'scratchings', 'tissues'].map {|item_name| item = Items::ITEMS[item_name]; "^L#{sprintf("%8d", item.price)}\u{20ab}^n #{item.name} - #{item.description}"}.join("\n"))
    elsif item_to_buy = Items::ITEMS[item_name]
      if item_to_buy.price == 0
        output "You can't buy that item."
      elsif purchased_item = item_to_buy.purchase_by(self)
        self.items.add(purchased_item)
        output_to_all "^Y\u{2192}^n #{cname} buys #{purchased_item.name}"
        save
      else
        output "You can't afford to buy #{item_to_buy.name}. It costs #{currency(item_to_buy.price)} and you only have #{currency(money)}."
      end
    else
      output "Unknown item '#{item_name}'. Type ^Lshop^n to view the items available."
    end
  end
  define_alias 'buy', 'shop'
  
  define_command 'partexchange' do |message|
    (old_vehicle_name, new_vehicle_name) = get_arguments(message, 2)
    if old_vehicle_name.blank? || new_vehicle_name.blank?
      vehicles = items.select {|i|['chopper', 'minibus', 'lada', 'subaru', 'skoda', 'ford', 'citroen' ].include?(i.name.downcase)}
      if vehicles.empty?
        output "You do not have any vehicles to part exchange."
      else
        output "^LSalesman tells you 'Unfortunately that rust means I can only offer you:'^n\n" + vehicles.map {|i|"#{sprintf("%15.15s", i.name)} #{currency(i.price / 2)}"}.join("\n") + "\nTo perform a part exchange, type ^Lpartexchange <old vehicle> <new vehicle>^n"
      end
    else
      old_vehicle = items.find(old_vehicle_name)
      new_vehicle = Items::ITEMS[new_vehicle_name]
      if old_vehicle.nil?
        output "Unknown vehicle to part exchange '#{old_vehicle_name}'"
      elsif new_vehicle.nil?
        output "Unknown vehicle to buy '#{new_vehicle_name}'. Type ^Lforecourt^n to list all the vehicles."
      elsif !['chopper', 'minibus', 'lada', 'subaru', 'skoda', 'ford', 'citroen' ].include?(old_vehicle.name.downcase)
        output "Sorry, only vehicles can be part exchanged."
      elsif new_vehicle.price <= (old_vehicle.price / 2)
        output "Sorry, you can only part exchange for something of higher value."
      elsif purchased_item = new_vehicle.purchase_by(self, old_vehicle.price / 2)
        self.items.deplete(old_vehicle.name)
        self.items.add(purchased_item)
        output_to_all "^Y\u{2192}^n #{cname} part exchanges a #{old_vehicle.name} for a #{new_vehicle.name}"
        save
      else
        output "You can't afford to buy #{new_vehicle.name}. It costs #{currency(new_vehicle.price - (old_vehicle.price / 2))} after the part exchange, and you only have #{currency(money)}."
      end
    end
  end
  
  define_command 'eat' do |item_name|
    if item_name.blank?
      output "Format: eat <item name>"
    else
      item = items.find(item_name)
      if item.nil?
        bait = fishing.baitbox.find(item_name) if item.nil? && !fishing.nil?
        if bait
          fishing.baitbox.deplete(bait.name)
          output_to_all "^Y\u{2192}^n #{cname} eats a #{bait.name.gsub(/s$/, '').downcase}."
          if ["Maggots", "Castors", "Worms"].include?(bait.name)
            self.bile ||= 0
            self.bile = self.bile + 1
            case self.bile
            when 1 then output "You feel slightly unwell."
            when 2 then output "You feel moderately unwell."
            when 3 then output "You feel very unwell."
            else        output "You feel like you are going to be sick."
            end
            if self.bile > 5
              c = Talker.command_list['vomit']
              c.execute(self, "") if c
            end
          end
          save
        else
          output "You don't have any #{item_name}. Type ^Linventory^n to see what you have."
        end
      elsif item.name == "LSD"
        items.deplete(item.name)
        self.tripping = Time.now + 3600
        self.drug_strength += 1
        output_to_all "^Y\u{2192}^n #{cname} eats an Lysergic acid diethylamide tablet"
        save
      elsif item.name == "PCP"
        items.deplete(item.name)
        self.tripping = Time.now + 3600
        self.drug_strength += 2
        output_to_all "^Y\u{2192}^n #{cname} chomps on some Phenylcyclohexylpiperidine"
        save
      elsif item.name == "Dice"
        items.deplete(item.name)
        output_to_all "^Y\u{2192}^n #{cname} swallowed a die"
        save
      elsif item.name == "Soap"
        items.deplete(item.name)
        output_to_all "^Y\u{2192}^n #{cname} eats soap, laugh at the state of #{gender == :male ? 'him' : 'her'}!"
        save
      elsif item.name == "Scratchings"
        items.deplete(item.name)
        self.wossed = nil
        self.brummed = Time.now + 600
        output_to_all "^Y\u{2192}^n #{cname} consumes a Pork Scratching!"
        save
      elsif item.name == "Conker"
        items.deplete(item.name)
        output_to_all "^Y\u{2192}^n #{cname} chomps down a conker, delicious!"
      else
        output "You can't eat #{item.name}."
      end
    end
  end
  
  define_command 'drink' do |item_name|
    if item_name.blank?
      output "Format: drink <item name>"
    else
      item = items.find(item_name)
      item = fishing.baitbox.find(item_name) if item.nil? && !fishing.nil?
      if item.nil?
        output "You don't have any #{item_name}. Type ^Linventory^n to see what you have."
      elsif ['Water', 'Wine', 'Half', 'Pint', 'Staylar', 'Vodka'].include?(item.name)
        drink_time = Time.now.to_i - last_drink.to_i
        if drink_time < 15
          output "You need another #{15 - drink_time.round(2)} seconds to finish consuming your current beverage."
        else
          self.last_drink = Time.now
          if item.name == 'Water'
            items.deplete(item.name)
            output_to_all "^Y\u{2192}^n #{cname} drinks 44cl of water"
          elsif item.name == 'Wine'
            items.deplete(item.name)
            output_to_all "^Y\u{2192}^n #{cname} drinks 175ml of wine (2 alcoholic units)"
            self.alcohol_units += 2
          elsif item.name == 'Half'
            items.deplete(item.name)
            output_to_all "^Y\u{2192}^n #{cname} drinks \u{00bd} a pint of Dragon Bitter"
            self.alcohol_units += 1
          elsif item.name == 'Pint'
            items.deplete(item.name)
            output_to_all "^Y\u{2192}^n #{cname} drinks 1 pint of Dragon Bitter"
            self.alcohol_units += 2
          elsif item.name == 'Staylar'
            items.deplete(item.name)
            output_to_all "^Y\u{2192}^n #{cname} drinks a bottle of Staylar"
            self.alcohol_units += 1
          elsif item.name == 'Vodka'
            items.deplete(item.name)
            output_to_all "^Y\u{2192}^n #{cname} drinks 7cl of Dragon Brand Vodka"
            self.alcohol_units += 3
          end
          save
        end
      else
        output "You can't drink #{item.name}."
      end
      debug_message "#{name} units #{alcohol_units}"
    end
  end
  
  define_command 'repair' do |item_name|
    if item_name.blank?
      output "Format: repair <item name>"
    else
      item = items.find(item_name)
      if item.nil?
        output "You don't have a #{item_name}. Type ^Linventory^n to see what you have."
      else
        if item.damage > 0.0
          if item.damage <= money
            self.money -= item.damage.to_i
            item.damage = 0.0
            save
            output "You have repaired your #{item.name}."
          else
            output "You can't afford to repair your #{item.name}"
          end
        else
          output "Your #{item.name} is not damaged."
        end  
      end
    end
  end
  
  define_command 'wipe' do |target_name|
    if target_name.blank?
      if !sneezed_on
        output "You don't need wiping clean."
      else
        item = items.find('tissues')
        if item.nil?
          output "You don't have any tissues to wipe yourself with!"
        else
          items.deplete('tissues')
          self.sneezed_on = false
          output_to_all "^G\u{2192}^n #{cname} wipes #{hisher} face with a tissue!"
          save
        end
      end
    else
      target = find_user(target_name)
      if target
        if !target.sneezed_on
          output "#{target.name} doesn't need wiping."
        else
          item = items.find('tissues')
          if item.nil?
            output "You don't have any tissues to wipe #{target.name} with!"
          else
            item2 = items.find('stick')
            if item2.nil?
              output "You can't reach #{target.name} from where you are standing."
            else
              items.deplete('tissues')
              items.deplete('stick')
              target.sneezed_on = false
              output_to_all "^G\u{2192}^n #{cname} cleans up #{target.name} with a tissue on a stick!"
            end
          end
        end
      end
    end
  end
  
  define_command 'gather' do |item_name|
    if item_name.blank?
      output "What do you want to gather?"
    elsif item_name =~ /conker/ && TalkerBase.instance.conkers_on_ground > 0
      item = items.find('conker')
      if item && item.quantity > 4
        output "There is no room for any more conkers in your sack."
      else
        self.items.add(Items::ITEMS['conker'])
        TalkerBase.instance.set_attribute(:conkers_on_ground, TalkerBase.instance.conkers_on_ground - 1)
        output "You pick up a conker."
      end
    elsif item_name =~ /stick/ && TalkerBase.instance.sticks_on_ground > 0
      item = items.find('stick')
      if item && item.quantity > 0
        output "You already have a stick in your hand, there is no room in your palm for another one."
      else
        self.items.add(Items::ITEMS['stick'])
        TalkerBase.instance.set_attribute(:sticks_on_ground, TalkerBase.instance.sticks_on_ground - 1)
        output "You pick up a stick."
      end
    else
      output "There are no #{pluralise(item_name, 2)} on the ground."
    end
  end
end
