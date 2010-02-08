# encoding: utf-8
=begin

● = \u{25cf}
◦ = \u{25e6}

A B C D E F G
◦ ◦ ◦ ◦ ◦ ◦ ◦
◦ ◦ ◦ ◦ ◦ ◦ ◦
◦ ◦ ◦ ◦ ◦ ◦ ◦
◦ ◦ ◦ ● ◦ ◦ ◦
◦ ◦ ◦ ● ◦ ◦ ◦
◦ ◦ ● ● ● ◦ ◦

^cA B C D E F G
^D◦^n ^D◦^n ^D◦^n ^D◦^n ^D◦^n ^D◦^n ^D◦^n
^D◦^n ^D◦^n ^R●^n ^Y●^n ^D◦^n ^D◦^n ^D◦^n
^D◦^n ^D◦^n ^Y●^n ^Y●^n ^Y●^n ^R●^n ^D◦^n
^D◦^n ^D◦^n ^R●^n ^R●^n ^Y●^n ^Y●^n ^D◦^n
^D◦^n ^D◦^n ^R●^n ^Y●^n ^R●^n ^Y●^n ^D◦^n
^D◦^n ^Y●^n ^R●^n ^R●^n ^R●^n ^Y●^n ^R●^n

^cA B C D E F G
^D◦^n ^D◦^n ^D◦^n ^D◦^n ^D◦^n ^D◦^n ^D◦^n
^D◦^n ^D◦^n ^r●^n ^Y●^n ^D◦^n ^D◦^n ^D◦^n
^D◦^n ^D◦^n ^y●^n ^y●^n ^Y●^n ^r●^n ^D◦^n
^D◦^n ^D◦^n ^r●^n ^r●^n ^y●^n ^Y●^n ^D◦^n
^D◦^n ^D◦^n ^r●^n ^y●^n ^r●^n ^y●^n ^Y●^n
^D◦^n ^y●^n ^r●^n ^r●^n ^r●^n ^y●^n ^r●^n

=end

class ConnectFourPlayer < Player
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
  
  def has_won?
    # unimplemented
    false
  end
  
end

class ConnectFour < Game
  def initialize(creator, opponent)
    super()
    piece = rand(2) + 1
    @players << ConnectFourPlayer.new(creator, :accepted, piece)
    @players << ConnectFourPlayer.new(opponent, nil, (piece == 2 ? 1 : 2))
    create_board
  end
  
  def self.find(user)
    super(user, 'Connect Four')
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
  
  def create_board
    self.data[:board] = (0..5).map {|row|[].fill(0, 0..6)}
  end
  
  def columnfull?(column)
    data[:board][5][column] > 0
  end
  
  def placepiece(column, piece)
    self.data[:board][self.data[:board].index(0)][column] = piece
  end

  def board
    buffer = "\n   ^BA B C D E F G\n"
    data[:board].reverse.each do |line| 
      buffer += render_line(line)
    end
    buffer
  end

  def render_line(data)
    data.map do |i| 
      if i == 0
        "^b\u{25e6}"
      elsif i == 1
        "^y\u{25cf}"
      elsif i == 2
        "^r\u{25cf}"
#      elsif i == 3
#        "^Y\u{25cf}"
#      else
#        "^R\u{25cf}"
      end
    end.join(" ") + "^n"
  end
end

module Commands
  define_command 'c4' do |message|
    game = ConnectFour.find(self)
    if game.nil?
      if message.blank?
        output "Format: c4 <opponent name>"
      else
        opponent = find_connected_user(message)
        if opponent
          if opponent == self
            output "You can't challenge yourself."
          else
            game = ConnectFour.find(opponent)
            if game
              output "Sorry, that user is already playing a game of Connect Four."
            else
              game = ConnectFour.new(self, opponent)
              opponent.output "^G-> ^n#{name} has challenged you to a game of Connect Four\n^LType 'c4 accept' or 'c4 decline'.^n"
              output Textfile.get_text("rules_cfour") + "\nYou challenge #{opponent.name} to a game of Connect Four."
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
          if column.nil?
            output "You must specify a column to place your piece in, from A to F."
          else
            if game.columnfull?(column)
              output "That column is full." 
            else
              game.placepiece(column, player.piece)
              if player.has_won?
                output game.board
                opponent.output game.board
                pay_out = opponent.pay_out
                output_to_all "^g\u{25ba}^n #{player.name} beats #{opponent.name} at Connect Four, winning #{pay_out}\u{20ab}!"
                self.money += pay_out
                save
                game.destroy
              else
                output game.board + pbuffer
                opponent.output game.board + obuffer
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
        output "You have already accepted the challenge."
      else
        player.accept
        game.players.each { |player| player.output player.preboard }
      end
    end
  end
  
  define_command 'c4 decline' do
    game = ConnectFour.find(self)
    if game.nil?
      output "You don't have a game to decline."
    else
      if !game.player(self).not_accepted?
        output "You have already accepted the challenge."
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
      opponent.output "#{name} has just quit your game of Connect Four!" if opponent
      output "You quit your game of Connect Four."
      game.destroy
    end
  end

end