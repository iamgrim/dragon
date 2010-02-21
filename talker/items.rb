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
    Item.new("Dice", "A six sided die", 1, 150)#,
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
        output_to_all "^Y\u{2192}^n #{cname} buys a #{purchased_item.name}"
        save
      else
        output "You can't afford to buy #{item_to_buy.name}. It costs #{item_to_buy.price}\u{20ab} and you only have #{money}\u{20ab}."
      end
    else
      output "Unknown item '#{item_name}'. Type ^Lbuy^n to view the items available."
    end
  end
  
end
