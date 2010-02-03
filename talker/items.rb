class Item
  attr_accessor :name, :description, :quantity, :price

  def initialize(name, description, quantity, price)
    @name = name
    @description = description
    @quantity = quantity
    @price = price
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