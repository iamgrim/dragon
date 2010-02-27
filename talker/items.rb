class Item
  attr_accessor :name, :description, :quantity, :price, :unique

  def initialize(name, description, quantity, price, unique=false)
    @name = name
    @description = description
    @quantity = quantity
    @price = price
    @unique = unique
  end

  def purchase_by(user)
    if user.money >= price
      user.money -= price
      clone
    else
      nil
    end
  end
end

class Items < Array
  SHOP = Items.new([
    Item.new("Dice", "A six sided die", 1, 150),
    Item.new("LSD", "Lysergic acid diethylamide", 1, 50),
    Item.new("Soap", "A surfactant cleaning compound, used for personal cleaning", 10, 200),
    Item.new("Water", "44cl of Dragon Mineral", 1, 100)
#    Item.new("Carbon Fishing Rod", "Requires 16 class 3 catches or above", 1, 15000, true)
  ])
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

module Commands

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
      output box("Dragon Worlde Shope", Items::SHOP.map {|item| "^L#{sprintf("%8d", item.price)}\u{20ab}^n #{item.name} - #{item.description}"}.join("\n"))
    elsif item_to_buy = Items::SHOP.find(item_name)
      if purchased_item = item_to_buy.purchase_by(self)
        self.items.add(purchased_item)
        output_to_all "^Y\u{2192}^n #{cname} buys #{purchased_item.name}"
        save
      else
        output "You can't afford to buy #{item_to_buy.name}. It costs #{item_to_buy.price}\u{20ab} and you only have #{money}\u{20ab}."
      end
    else
      output "Unknown item '#{item_name}'. Type ^Lbuy^n to view the items available."
    end
  end
  define_alias 'buy', 'shop'
  
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
            else        output "You feel like you are doing to be sick."
            end
            if self.bile > 5
              c = Commands.lookup('vomit')
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
        output_to_all "^Y\u{2192}^n #{cname} eats an LSD tablet"
        save
      elsif item.name == "Dice"
        items.deplete(item.name)
        output_to_all "^Y\u{2192}^n #{cname} swallowed a die"
        save
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
      elsif item.name == 'Water'
        items.deplete(item.name)
        output_to_all "^Y\u{2192}^n #{cname} drinks some water"
      else
        output "You can't drink #{item.name}."
      end
    end
  end
  
end
