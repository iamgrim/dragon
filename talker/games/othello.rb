# encoding: utf-8

# this is horrible

class OthelloPlayer < Player
  attr_accessor :piece
  
  def initialize(user, state, piece, game)
    super(user, state)
    self.piece = piece
    @game = game
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
  
  def score
    @game.data[:board].flatten.select{|x| x == piece}.length
  end

end

class Othello < Game
  attr_accessor :data
  attr_accessor :stake
  
  def initialize(creator, opponent, stake)
    super()
    piece = rand(2) + 1
    @players << OthelloPlayer.new(creator, :accepted, piece, self)
    @players << OthelloPlayer.new(opponent, nil, 3 - piece, self)
    @data = {}
    @stake = stake
    create_board
  end
  
  def self.find(user)
    super(user, 'Othello')
  end
  
  def challenger
    @players.first
  end
  
  def description
    "#{@players[0].name} and #{@players[1].name} are engaged in an Othello duel"
  end
  
  def get_move(string)
    if (string.downcase =~ /([a-h])([1-8])/) == 0
      [ $2.to_i - 1, $1.ord - 97 ]
    else
      [ nil, nil ]
    end
  end
    
  def create_board
    self.data[:board] = (0..7).map {|row|[].fill(0, 0..7)}
    self.data[:board][3][3] = 1
    self.data[:board][3][4] = 2
    self.data[:board][4][3] = 2
    self.data[:board][4][4] = 1
  end

  def is_legal_move?( x, y, xd, yd, us, first )
    x += xd
    y += yd

    if x.between?(0,7) and y.between?(0,7)
      if self.data[:board][y][x] == 0
        return false
      elsif self.data[:board][y][x] == us
        return (first == 1) ? false : true
      else
        return is_legal_move?(x, y, xd, yd, us, 0)
      end
    end
    return false
  end

  def test_line(x, y, xd, yd, us, first)
     retval = 0
     x += xd
     y += yd

     if x.between?(0,7) and y.between?(0,7)
        if self.data[:board][y][x] == 0
	  return nil
        elsif self.data[:board][y][x] == us
          return (first == 1) ? nil : true
        else # it must be them:
          retval = test_line(x, y, xd, yd, us, 0) 
          if retval == true
            self.data[:board][y][x] = us;
          end
          return retval
        end
     end
     return nil
  end

  def place_piece(x, y, piece)
    dirs = [ [0, 1], [1, 1], [1, 0], [1, -1], [0, -1], [-1, -1], [-1, 0], [-1, 1] ]
    score = dirs.collect {|dir| self.test_line(x, y, dir[0], dir[1], piece, 1)}
    if (score.compact.length > 0)
      self.data[:board][y][x] = piece;
      return true
    end
    return false
  end

  def has_legal_move? (piece)
    dirs = [ [0, 1], [1, 1], [1, 0], [1, -1], [0, -1], [-1, -1], [-1, 0], [-1, 1] ]
    for x in 0...8
      for y in 0...8
        if (self.data[:board][y][x] == 0)
          dirs.each {|dir| if self.is_legal_move?(x, y, dir[0], dir[1], piece, 1) then return true end }
        end
      end
    end
    return false
  end
  
  def over?
    return !self.has_legal_move?(1) && !self.has_legal_move?(2)
  end

  def board
    n = 64
    buffer = self.data[:board].collect {|line|
	    n += 1
	    "^c #{n.chr} ^n^f #{self.render_line(line)}^n"
    }
    buffer = buffer.insert(0, "\n\n    ^c1 2 3 4 5 6 7 8")

    buffer[2] += sprintf(" ^G%-2.2s^n ^W%-15.15s #{(@players[0].piece == 1 ? '^W' : '^D') + "\u{25cf}"}^n (%d stones)", self.turn?(@players[0]) ? "\u{2192}" : '', @players[0].name, @players[0].score )
    buffer[3] += sprintf(" ^G%-2.2s^n %-15.15s #{(@players[1].piece == 1 ? '^W' : '^D') + "\u{25cf}"}^n (%d stones)", self.turn?(@players[1]) ? "\u{2192}" : '', @players[1].name, @players[1].score )

    buffer.map! {|line| line += "\n" }
    buffer.join()
  end

  def render_line(row)
    row.map do |i| 
      if i == 0
        "^n^f\u{00b7} "
      elsif i == 1
        "^W\u{25cf} "
      elsif i == 2
        "^D\u{25cf} "
      else
        "^Y* "
      end
    end.join() + "^n"
  end
end

module Commands
  define_command 'oth' do |message|
    game = Othello.find(self)
    if game.nil?
      if message.blank?
        output "Format: oth <opponent name>"
      else
        args = message.split(/ /)
        target = args[0]
        stake = args[1]
      
        opponent = find_connected_user(target)
        if opponent
          if opponent == self
            output "You can't challenge yourself."
          elsif ( Othello.find(opponent) )
            output "Sorry, #{target} is already playing Othello."
	  else
  	    if stake and stake.match(/[0-9]+/)
              if stake.to_i > opponent.money
                output "#{target} can't afford a stake that high."
		stake = nil
              elsif stake.to_i > self.money
                output "You can't afford a stake that high."
		stake = nil
	      end
            else
              stake = "0"
            end

	    if stake != nil
              game = Othello.new(self, opponent, stake.to_i)
              notice = "You challenge #{opponent.name} to a game of Othello"
	      challenge = "^G\u{2192} ^n#{name} challenges you to a game of Othello"
	      if stake.to_i > 0
  	        notice += " for a stake of ^W#{currency(stake)}^n"
	        challenge += " for a stake of ^W#{currency(stake)}^n"
	      end
              opponent.output "#{challenge}\n^LType 'oth accept' or 'oth decline'.^n"
              output "#{notice}^n."
	    end
  	  end
	end
      end
    else
      player = game.player(self)
      opponent = game.find_opponent(player)
      if player.not_accepted?
        output "Waiting for you to accept the challenge."
      elsif opponent.not_accepted?
        output "Waiting for #{opponent.name} to accept the challenge."
      elsif !game.turn?(player)
        output game.board + "It is #{opponent.name}'s turn."
      elsif message.blank?
        output game.board + (game.turn?(player) ? "It is your turn." : "It is #{opponent.name}'s turn.")
      else
        (x, y) = game.get_move(message)
        if x.nil? or message.length > 2
          output "You must choose a square, from A1 to H8."
        elsif game.data[:board][y][x] != 0
          output "There is already a stone in that square."
        elsif ( !game.place_piece(x, y, player.piece) )
          output "That's an illegal move."
	elsif game.over?
          game.players.each {|player| player.output game.board }
          if player.score > opponent.score
            winner = player
            loser = opponent
          elsif player.score < opponent.score
            winner = opponent
            loser = player
          end

	  if defined? winner
            output_to_all "^g\u{2192}^n #{winner.name} thwarted #{loser.name} at Othello"
            if game.stake > 0
              find_connected_user(winner.name).money += game.stake * 2
	    end
          else
            output_to_all "^g\u{2192}^n #{player.name} and #{opponent.name} drew at Othello."
            if game.stake > 0
              find_connected_user(player.name).money += game.stake
              find_connected_user(opponent.name).money += game.stake
            end
	  end
          save
          game.destroy
        else
          game.next_turn
          u = find_connected_user(player.name)
          o = find_connected_user(opponent.name)
	  if (!game.has_legal_move?(game.player_taking_turn.piece))
            game.next_turn
            game.players.each { |player| player.output game.board }
            player.output "#{u.get_timestamp}You put your stone at #{message.upcase}. #{opponent.name} can't move. Go again!"
            opponent.output "#{o.get_timestamp}#{player.name} places a stone at #{message.upcase}. You can't move and miss a turn."
	  else
            game.players.each { |player| player.output game.board }
            player.output "#{u.get_timestamp}You put your stone at #{message.upcase}."
            opponent.output "#{o.get_timestamp}#{player.name} places a stone at #{message.upcase}. Your turn!"
	  end
	end
      end
    end
  end

  define_command 'oth accept' do
    game = Othello.find(self)
    if game.nil?
      output "You don't have a game to accept."
    else
      player = game.player(self)
      if !player.not_accepted?
        execute_parent_command("oth")
      else
        player.accept
        game.start
        game.players.each { |player| 
          player.output game.board
          find_connected_user(player.name).money -= game.stake
        }
      end
    end
  end
  
  define_command 'oth decline' do
    game = Othello.find(self)
    if game.nil?
      output "You don't have a game to decline."
    else
      if !game.player(self).not_accepted?
        execute_parent_command("oth")
      else
        game.challenger.output "#{name} declines your offer of a game of Othello."
        output "You decline the offer of a game of Othello from #{game.challenger.name}."
        game.destroy
      end
    end
  end
  
  define_command 'oth quit' do
    game = Othello.find(self)
    if game.nil?
      execute_parent_command('oth')
    else
      player = game.player(self)
      opponent = game.find_opponent(player)
      
      if game.stake > 0 and player.accepted? and opponent.accepted?
        opponent.output "#{name} has juste quit thy game of Othello, forfeiting their stake of #{currency(game.stake)}!"
        output "You quit Othello, forfeiting thy stake of #{currency(game.stake)}."
        o = find_user(opponent.name)
        if o
          o.money += game.stake * 2
          o.save
        end
      else
        opponent.output "#{name} has juste quit thy game of Othello!" if opponent
        output "You quit thy game of Othello."
      end
      game.destroy
    end
  end
end
