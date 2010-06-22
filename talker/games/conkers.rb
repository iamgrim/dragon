class ConkerPlayer < Player
  def initialize(user, state)
    super(user, state)
  end
  
  def accept
    self.state = :accepted if state.nil?
  end
  
  def not_accepted?
    state.nil?
  end

  def accepted?
    state == :accepted
  end
  
end

class Conkers < Game
  def initialize(creator, opponent)
    super()
    @players << ConkerPlayer.new(creator, :accepted)
    @players << ConkerPlayer.new(opponent, nil)
  end
  
  def self.find(user)
    super(user, 'Conkers')
  end
  
  def description
    "#{@players[0].name} and #{@players[1].name} are banging their conkers together"
  end
  
  def challenger
    @players.first
  end
  
end

module Talker

  define_command 'conkers' do |message|
    game = Conkers.find(self)
    if game.nil?
      if message.blank?
        output "Format: conkers <opponent name>"
      else
        opponent = find_connected_user(message)
        if opponent
          if opponent == self
            output "You can't challenge yourself."
          else
            game = Conkers.find(opponent)
            if game
              output "Sorry, that user is already playing a game of Conkers."
            else
              game = Conkers.new(self, opponent)
              opponent.output "^L> ^n#{cname} has challenged you to a game of Conkers\n^nType ^Lconkers accept^n or ^Lconkers decline^n."
              output "\nYou challenge #{opponent.name} to a game of Conkers."
            end
          end
        end
      end
    else
      output "Thy game ise down fore maintenance"
    end
  end
  
  define_command 'conkers accept' do
    game = Conkers.find(self)
    if game.nil?
      output "You don't have a game to accept."
    else
      p = game.player(self)
      if !p.not_accepted?
        output "You have already accepted the challenge."
      else
        p.accept
        game.players.each { |p| p.output "Sorry, there are no conkers on the ground so you can't play right now." }
        game.destroy
      end
    end
  end
  
  define_command 'conkers decline' do
    game = Conkers.find(self)
    if game.nil?
      output "You don't have a game to decline."
    else
      if !game.player(self).not_accepted?
        output "You have already accepted the challenge."
      else
        game.challenger.output "#{name} declines your Conkers offer."
        output "You decline the Conkers offer from #{game.challenger.name}."
        game.destroy
      end
    end
  end
  
  define_command 'conkers quit' do
    game = Conkers.find(self)
    if game.nil?
      execute_parent_command('conkers')
    else
      p = game.player(self)
      opp = game.find_opponent(p)
      opp.output "#{name} has just quit your game of conkers!" if opp
      output "You quit your game of conkers."
      game.destroy
    end
  end
end