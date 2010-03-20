class CommunityService
  attr_accessor :completed_work, :required_work
  attr_reader :colour, :location
  
  COLOURS = ['red', 'blue', 'pink', 'orange', 'green', 'gold', 'white', 'black', 'purple']
  PAINT_LOCATION = ['fence', 'wall', 'ceiling']
  
  def initialize(mins)
    @colour = COLOURS[rand(COLOURS.length)]
    @location = PAINT_LOCATION[rand(PAINT_LOCATION.length)]
    @required_work = rand(8) + 6
    @completed_work = 0
    @end_time = Time.now + (mins * 60)
  end
  
  def perform_work
    @completed_work += 1
  end
  
  def completed?
    @completed_work >= @required_work
  end
  
  def tick(user)
    if Time.now > @end_time && !completed?
      user.community_service = nil
      if user.money >= 100
        user.money -= 100
        user.output_to_all "^g\u{2192}^n #{user.name} failed to complete their community service and has been fined #{currency(100)}"
        user.save
      else
        user.output_to_all "^g\u{2192}^n #{user.name} failed to complete their community service and has been sent to prison"
        user.save
        user.disconnect
      end
    end
  end
end

# encoding: utf-8
module Commands
  define_command 'games' do
    buffer = ""
    if Game.games.length > 0
      Game.games.each do |game|
        buffer += "^W\u{25CF}^n #{game.description}\n"
      end
    else
      buffer += "There are no games in progress."
    end
    output box("Games", buffer)
  end
  
  define_command 'dice' do
    user_dice = items.find("dice")
    if user_dice.nil? || user_dice.quantity < 2
      output "You need two dice to play."
    else
      num_word = %w{One Two Three Four Five Six}
      faces = [["     ", "  \u{25cf}  ", "     "],
               ["\u{25cf}    ", "     ", "    \u{25cf}"],
               ["\u{25cf}    ", "  \u{25cf}  ", "    \u{25cf}"],
               ["\u{25cf}   \u{25cf}", "     ", "\u{25cf}   \u{25cf}"],
               ["\u{25cf}   \u{25cf}", "  \u{25cf}  ", "\u{25cf}   \u{25cf}"],
               ["\u{25cf}   \u{25cf}", "\u{25cf}   \u{25cf}", "\u{25cf}   \u{25cf}"]]
    
      roll1 = rand(6)
      roll2 = rand(6)
      score = roll1 + roll2 + 2
    
      double_text = [
        "Snake ears, Double Ones!",
        "Stirling Moss, Double Twos",
        "Milton Keynes, Double Threes",
        "Uncle Monty, Double Fours",
        "Snake eyes, Double Fives",
        "Good Role, Double Sixes"
      ]
    
      result_text = if roll1 == roll2
        double_text[roll1]
      else
        "A #{num_word[roll1]} and a #{num_word[roll2]}"
      end
    
      output "    ^B\u{250c}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2510}   \u{250c}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2510}      ^NYou roll two dice and get:
    ^B\u{2502} ^Y#{faces[roll1][0]}^B \u{2502}   \u{2502} ^Y#{faces[roll2][0]}^B \u{2502}      ^N#{result_text}
    ^B\u{2502} ^Y#{faces[roll1][1]}^B \u{2502}   \u{2502} ^Y#{faces[roll2][1]}^B \u{2502}^N
    ^B\u{2502} ^Y#{faces[roll1][2]}^B \u{2502}   \u{2502} ^Y#{faces[roll2][2]}^B \u{2502}      ^NTotal Score: #{score}
    ^B\u{2514}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2518}   \u{2514}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2518}^N"
    end
  end
  define_alias 'dice', 'roll', 'd'
  
  define_command 'coin' do
    if money <= 0
      output "You can't afford to play."
    else
      self.money -= 1
      chance = rand(25000)

      if chance < 12500
        output "^Y          .-'''''-.\n        .'         `.\n       :   |@++@|    :		^n^LYou flip the coin and you get:\n^Y      :    00  o >    :\n      :   00)   =/    :		^GH E A D S\n^Y       :  O zzzz}    :\n        `.         .'\n          `-.....-'^n\n"
      elsif chance > 12500
        output "^Y          .-'''''-.\n        .'    |    `.\n       :   {-----}   :	        ^n^LYou flip the coin and you get:\n^Y      :   oo#####oo   :\n      :   o ##### o   :        ^R T A I L S\n ^Y      :  o ##### o  :\n        `.         .'\n          `-.....-'^n\n"
      else
        output "^Y       ___\n     .    .. 			^n^LYou flip the coin and it lands\n^Y    .  ;   ..	      	^P        on its edge.\n ^Y   .   ;  ..\n^r ..__^Y.^r____^Y..^r__..^n\n"
        output_to_all "^G\u{2192}^n #{name} has been Joe Palookered! The coin landed on its edge!"
        output_to_all "^G\u{2192}^n #{name} won 1,000,000 drogna"
        self.money = money + 1000000
        save
      end
    end
  end
  define_alias 'coin', 'c'

  define_command 'omnibus' do |message|
    (origin, destination, time) = get_arguments(message, 3)
    if origin.blank? || destination.blank? || time.blank?
      output "Format: omnibus <origin> <destination> <time>"
    else
      output "Sorry no bus service at that time."
    end
  end

  define_command 'give' do |message|
    (recipient_name, amount) = get_arguments(message, 2)
    amount = amount.to_i
    if recipient_name.blank? || amount < 1
      output "Format: give <user> <amount>"
    else
      recipient = find_connected_user(recipient_name)
      if recipient
        if amount > money
          output "You don't have that much to give."
        elsif recipient == self
          output "You already own that."
        else
          self.money -= amount
          recipient.money += amount
          output_to_all "^g\u{2192}^n #{cname} has just given #{recipient.cname} #{amount} drogna!"
          save
          recipient.save
        end
      end
    end
  end

#  define_command 'donate' do |message|
#    amount = message.to_i
#    if message.blank? || amount < 1
#      output "Format: donate <amount>"
#    else
#      recipient = self
#      while recipient == self do
#        recipient = connected_users.values[rand(connected_users.length)]
#      end
#      output_to_all "^g\u{2192}^n #{cname} generously donates #{amount}\u{20ab} to #{recipient.cname}!"
#      self.money -= amount
#      self.donations += amount
#      recipient.money += amount
#      save
#      recipient.save
#    end
#  end
  
  define_command 'steal' do |message|
    (recipient_name, amount) = get_arguments(message, 2)
    amount = amount.to_i
    if recipient_name.blank? || amount < 1
      output "Format: steal <user> <amount>"
    else
      recipient = find_connected_user(recipient_name)
      if recipient
        if amount > recipient.money
          output "They don't have that much to steal."
        elsif recipient == self
          output_to_all "^g\u{2192}^n #{cname} attempts to commit insurance fraud, and is imprisoned!"
          disconnect
        else
	        r = rand(2 + (amount / 10).round)
          if r < 1
            self.money += amount
            recipient.money -= amount
            output "You successfully stole #{currency(amount)} from #{recipient.cname}!"
            recipient.output "Your pocket feels lighter than before."
            save
            recipient.save
          else
            if community_service.nil?
              output_to_all "^g\u{2192}^n #{cname} attempts to steal from #{recipient.cname}, and receives community service!"
              self.community_service = CommunityService.new(1)
              output "You have one minute to paint a #{community_service.required_work} metre #{community_service.location} #{community_service.colour}. Begin now."
            else
              output_to_all "^g\u{2192}^n #{cname} attempts to steal from #{recipient.cname} while on community service, and is therefore sent to prison"
              disconnect
            end
          end
        end
      end
    end
  end
  
  define_command 'paint' do |message|
    (object_name, paint_colour) = get_arguments(message, 2)
    if object_name.blank? || paint_colour.blank?
      output "Format: paint <object> <colour>"
    else
      if CommunityService::PAINT_LOCATION.include?(object_name)
        if community_service
          if object_name == community_service.location
            if paint_colour == community_service.colour
              community_service.perform_work
              if community_service.completed?
                self.community_service = nil
                self.save
                output "You have successfully completed your community service."
              else
                output "You have completed #{community_service.completed_work} metres of the #{community_service.location}."
              end
            else
              output "That is the wrong colour you fucking idiot, do you want to be sent to prison?"
            end
          else
            output "You are supposed to be painting the #{community_service.location}, not the #{object_name}!"
          end
        else
          output "You can't paint that right now."
        end
      else
        output "What is that?"
      end
    end
  end
  
#  define_command 'arson' do
#    if Talker.instance.on_fire.empty?
#      Talker.instance.start_fire 
#      output "You bad person, look what you did"
#    else
#      output "The talker is already on fire"
#    end
#  end
  
  define_command 'hose' do |target_name|
    if target_name.blank?
      output "Format: hose <command or user name>"
    else
      if !resident?
        output "Only qualified personnel can use the fire safety equipment."
      else
        if Talker.instance.on_fire.has_key?(target_name)
          case rand(5)
          when 0
            Talker.instance.on_fire.delete(target_name)
            output_to_all "^C\u{2192}^n #{name} has put out #{target_name}, receiving a #{currency(25)} reward"
            self.money += 25
            save
          when 1
            output "You have reduced the heat but the fire is still burning."
          when 2
            output "This fire is particularly obstreperous, keep trying."
          when 3
            output "The fire appeared to go out but then it came back again."
          else
            output "You have not managed to put that out, keep trying."
          end
        else
          target = find_connected_user(target_name, :silent => true)
          if target
            if target == self
              output "The hose is too powerful to turn on yourself."
            else
              if target.vomited_on
                target.vomited_on = nil
                output_to_all "^B\u{2192}^n #{name} sprays #{target.name} with water, cleaning the vomit off #{target.gender == :male ? 'him' : 'her'}!"
              else
                if rand(3) == 0
                  output_to_all "^R\u{2192}^n #{name} has been fined #{currency(50)} for misuse of fire safety equipment!"
                  self.money -= 50
                  save
                else
                  output_to_all "^B\u{2192}^n #{name} sprays #{target.name} with water from the hose!"
                end
              end
            end
          else
            output "#{target_name} is not on fire."
          end
        end
      end
    end
  end
  
  define_command 'vomit' do |target_name|
    if bile.nil? || bile < 4
      output "You do not have enough bile in your stomach."
    else
      target = target_name.blank? ? self : find_user(target_name)
      if target
        if target == self
          output_to_all vomit_string("\u{2192} #{name} vomits all over #{gender == :male ? 'him' : 'her'}self!")
        else
          output_to_all vomit_string("\u{2192} #{name} vomits all over #{target.name}!")
        end
        self.bile = 0
        target.vomited_on = true
        if drug_strength > 2
          self.drug_strength -= 1
          output "You feel slightly better."
        end
        save
      end
    end
  end
  
  define_command 'wash' do
    soap = items.find('Soap')
    water = items.find('Water')
    if soap.nil?
      output "You don't have any soap to wash with!"
    elsif water.nil?
      output "You don't have any water to wash with!"
    else
      items.deplete('Soap')
      items.deplete('Water')
      self.vomited_on = nil
      output_to_all "^B\u{2192}^n #{name} washes themselves clean!"
    end
  end
  
  define_command 'pray' do |type|
    self.prayer_status ||= [0, 0]
    (our_father, hail_mary) = self.prayer_status
    if type =~ /^ou/
      output "^L> You tell God \u{2018}Our Father, who art in heaven, hallowed be thy name. Thy Kingdom come, thy will be done, on earth as it is in heaven. Give us this day our daily bread. And forgive us our trespasses, as we forgive those who trespass against us. And lead us not into temptation, but deliver us from evil. For thine is the kingdom, the power and the glory. for ever and ever. Amen\u{2019}^n"
      self.prayer_status = [our_father + 1, hail_mary]
    elsif type =~ /^ha/
      output "^L> You tell God \u{2018}Hail Mary, full of grace, the Lord is with thee; blessed art thou among women, and blessed is the fruit of thy womb, Jesus. Holy Mary, Mother of God, pray for us sinners, now and at the hour of our death. Amen\u{2019}^n"
      self.prayer_status = [our_father, hail_mary + 1]
    elsif type =~ /^ho/
      output "^L> You sing to God \u{266a} Give me joy in my heart, keep me praising, Give me joy in my heart, I pray, Give me joy in my heart, keep me praising, Keep me praising 'till the break of day. Sing hosanna, sing hosanna, Sing hosanna to the King of kings! Sing hosanna, sing hosanna, Sing hosanna to the King. \u{266a}^n"
      self.prayer_status = [0, 0]
    else
      output "Format: pray <our father|hail mary|hosanna>"
    end
    (our_father, hail_mary) = self.prayer_status
    if our_father == 4 && hail_mary == 1
      water = items.find('Water')
      if water
        water.name = 'Wine'
        output_to_all "^B\u{2192}^n #{name} prayers have been answered, #{gender == :male ? 'his' : 'her'} water has mysteriously turned in to wine!"
        self.prayer_status = [0, 0]
      end
    end
  end
end