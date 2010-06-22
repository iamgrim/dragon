# encoding: utf-8
=begin

● = \u{25cf}
◦ = \u{25e6}

=end

class ConnectFourPlayer < Player
  attr_accessor :piece
  
  def initialize(user, state, piece)
    super(user, state)
    self.piece = piece
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

class ConnectFour < Game
  attr_accessor :data
  attr_accessor :stake
  
  def initialize(creator, opponent, stake)
    super()
    piece = rand(2) + 1
    @players << ConnectFourPlayer.new(creator, :accepted, piece)
    @players << ConnectFourPlayer.new(opponent, nil, (piece == 2 ? 1 : 2))
    @data = {}
    @stake = stake
    create_board
    get_winning_moves
  end
  
  def self.find(user)
    super(user, 'ConnectFour')
  end
  
  def challenger
    @players.first
  end
  
  def description
    "#{@players[0].name} and #{@players[1].name} are playing Connect Four"
  end
  
  def get_move(string)
    if (string.downcase =~ /([a-g])/) == 0
      $1.ord - 97
    else
      nil
    end
  end
  
  def get_winning_moves
    self.data[:winning_moves] = []
    
    # verticals
    column = 0
    while column < 6 do
      row = 0
      while row < 3 do
        move = []
        piece = 0
        while piece <= 3 do
          move[piece] = {:row => row+piece, :column => column}
          piece += 1
        end
        self.data[:winning_moves][self.data[:winning_moves].length] = move
        row += 1
      end
      column += 1
    end
    
    # horizontals
    row = 0
    while row <= 5 do
      column = 0
      while column < 4 do
        move = []
        piece = 0
        while piece <= 3 do
          move[piece] = {:row => row, :column => column+piece}
          piece += 1
        end
        self.data[:winning_moves][self.data[:winning_moves].length] = move
        column += 1
      end
      row += 1
    end
    
    # diagonals
    column = 0
    while column < 4 do
      row = 0
      while row < 3 do
        # south-west to north-east diagonals
        move = []
        piece = 0
        while piece <= 3 do
          move[piece] = {:row => row+piece, :column => column+piece}
          piece += 1
        end
        self.data[:winning_moves][self.data[:winning_moves].length] = move
        
        # north-west to south-east diagonals
        move = []
        piece = 0
        while piece <= 3 do
          move[piece] = {:row => row-piece+3, :column => column+piece}
          piece += 1
        end
        self.data[:winning_moves][self.data[:winning_moves].length] = move
        row += 1
      end
      column += 1
    end
  end
  
  def won?(player)
    data[:winning_moves].each do |move|
      pieces_in_a_row = 0
      move.each do |piece|
        if data[:board][piece[:row]][piece[:column]] == player.piece
          pieces_in_a_row += 1
        end
      end
      if pieces_in_a_row == 4
        move.each do |piece|
          self.data[:board][piece[:row]][piece[:column]] = 3
        end
        return true
      end
    end
    false
  end
  
  def create_board
    self.data[:board] = (0..5).map {|row|[].fill(0, 0..6)}
  end
  
  def columnfull?(column)
    data[:board][5][column] > 0
  end
  
  def drawn?
    full_columns = 0
    data[:board][5].each do |top|
      full_columns += top > 0 ? 1 : 0
    end
    full_columns == 7
  end
  
  def placepiece(column, piece)
    empty_row = 0
    data[:board].each do |row|
      if row[column] > 0 then
        empty_row += 1
      end
    end
    self.data[:board][empty_row][column] = piece
  end

  def board
    buffer = "\n\n ^CA B C D E F G\n"
    i = 6
    data[:board].reverse.each do |line| 
      if i == 4
        buffer += sprintf("^v #{render_line(line)}^v ^n  ^G%-2.2s^n %-15.15s #{(@players[0].piece == 1 ? '^Y' : '^R') + "\u{25cf}"}\n", self.turn?(@players[0]) ? "\u{2192}" : '', @players[0].name)
      elsif i == 3
        buffer += sprintf("^v #{render_line(line)}^v ^n  ^G%-2.2s^n %-15.15s #{(@players[1].piece == 1 ? '^Y' : '^R') + "\u{25cf}"}\n", self.turn?(@players[1]) ? "\u{2192}" : '', @players[1].name)
      else
        buffer += "^v #{render_line(line)}^v ^n\n"
      end
      i -= 1
    end
    buffer
  end

  def render_line(data)
    data.map do |i| 
      if i == 0
        "^B\u{25e6}"
      elsif i == 1
        "^Y\u{25cf}"
      elsif i == 2
        "^R\u{25cf}"
      else
        "^W\u{25cf}"
      end
    end.join(" ") + "^n"
  end
end

module Talker
  define_command 'c4' do |message|
    game = ConnectFour.find(self)
    if game.nil?
      if message.blank?
        output "Format: c4 <opponent name>"
      else
        target = message.split(/ /)[0]
        stake = message.split(/ /)[1]
        opponent = find_connected_user(target)
        if opponent
          if opponent == self
            output "You can't challenge yourself."
          else
            game = ConnectFour.find(opponent)
            if game
              output "Sorry, that user is already playing a game of Connect Four."
            else
              if stake and stake.match(/[0-9]+/)
                if stake.to_i > opponent.money
                  output "That user cannot afford a stake that high."
                elsif stake.to_i > self.money
                  output "You don't have enough money for a stake that high."
                else
                  game = ConnectFour.new(self, opponent, stake.to_i)
                  opponent.output "^G\u{2192} ^n#{name} has challenged you to a game of Connect Four for a stake of ^W#{currency(stake)}^n\n^LType 'c4 accept' or 'c4 decline'.^n"
                  output "You challenge #{opponent.name} to a game of Connect Four with a stake of ^W#{currency(stake)}^n."
                end
              else
                game = ConnectFour.new(self, opponent, 0)
                opponent.output "^G\u{2192} ^n#{name} has challenged you to a game of Connect Four\n^LType 'c4 accept' or 'c4 decline'.^n"
                output "You challenge #{opponent.name} to a game of Connect Four."
              end
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
      else
        if message.blank?
          output game.board + (game.turn?(player) ? "It is your turn." : "It is #{opponent.name}'s turn.")
        else
          column = game.get_move(message)
          if column.nil? or message.length > 1
            output "You must specify a column to place your piece in, from A to G."
          else
            if game.columnfull?(column)
              output "That column is full."
            else
              game.placepiece(column, player.piece)
              game.next_turn
              if game.won?(player)
                output game.board
                opponent.output game.board
                if game.stake > 0
                  find_connected_user(player.name).money += game.stake * 2
                  output_to_all "^g\u{2192}^n #{player.name} beats #{opponent.name} at Connect Four, winning #{currency(game.stake)}!"
                else
                  output_to_all "^g\u{2192}^n #{player.name} has beaten #{opponent.name} at Connect Four!"
                end
                save
                game.destroy
              elsif game.drawn?
                output game.board
                opponent.output game.board
                if game.stake > 0
                  find_connected_user(player.name).money += game.stake
                  find_connected_user(opponent.name).money += game.stake
                end
                output_to_all "^g\u{2192}^n #{player.name} and #{opponent.name} have drawn at Connect Four!"
                save
                game.destroy
              else
                game.players.each { |player| player.output game.board }
                u = find_connected_user(player.name)
                o = find_connected_user(opponent.name)
                player.output "#{u.get_timestamp}You place your piece in column #{message.upcase}"
                opponent.output "#{o.get_timestamp}#{player.name} places a piece in column #{message.upcase}"
              end
            end
          end
        end
      end
    end
  end
  
  define_command 'c4 accept' do
    game = ConnectFour.find(self)
    if game.nil?
      output "You don't have a game to accept."
    else
      player = game.player(self)
      if !player.not_accepted?
        execute_parent_command("c4")
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
  
  define_command 'c4 decline' do
    game = ConnectFour.find(self)
    if game.nil?
      output "You don't have a game to decline."
    else
      if !game.player(self).not_accepted?
        execute_parent_command("c4")
      else
        game.challenger.output "#{name} declines your offer of a game of Connect Four."
        output "You decline the offer of a game of Connect Four from #{game.challenger.name}."
        game.destroy
      end
    end
  end
  
  define_command 'c4 quit' do
    game = ConnectFour.find(self)
    if game.nil?
      execute_parent_command('c4')
    else
      player = game.player(self)
      opponent = game.find_opponent(player)
      
      if game.stake > 0 and player.accepted? and opponent.accepted?
        opponent.output "#{name} has just quit your game of Connect Four forfeiting their stake of #{currency(game.stake)}!"
        output "You quit your game of Connect Four, forfeiting your stake of #{currency(game.stake)}."
        o = find_user(opponent.name)
        if o
          o.money += game.stake * 2
          o.save
        end
      else
        opponent.output "#{name} has just quit your game of Connect Four!" if opponent
        output "You quit your game of Connect Four."
      end
      game.destroy
    end
  end

end