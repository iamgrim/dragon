# encoding: utf-8

class QuizPlayer < Player
  attr_accessor :mark
  attr_accessor :answer
  
  def initialize(user)
    super(user, nil)
    @score = 0
    @answer = nil
  end

  def correct?
    @mark == :tick
  end

  def wrong?
    @mark == :cross
  end

  def answered?
    !@answer.nil?
  end
end

class Quiz < Game
  attr_accessor :data
  attr_accessor :prize
  attr_accessor :running
  attr_accessor :round
  attr_accessor :question
  attr_accessor :answer
  
  def initialize(quizmaster, prize)
    super()
    @players << QuizPlayer.new(quizmaster)
    @data = {}
    @prize = prize
    @round = 0
    @question = nil
    @answer = nil
  end

  # I doubt that this is the right way to do this:  

  def Quiz.find()
    games = @@games.select {|g| g.class.name == 'Quiz' }
    games.empty? ? nil : games.first
  end
  
  def hash_players(arr = @players)
    return Hash[*arr.collect{|p| [p.name.downcase, p] }.flatten]
  end

 # terms

  def quizmaster
    @players.first
  end
  
  def contestants
    @players.reject {|x| is_quizmaster?(x)}.sort{|a,b| a.score <=> b.score}
  end

  def description
    "#{self.quizmaster.name} is running a quiz\n"
  end

  def add_player (p)
    @players << QuizPlayer.new(p)
  end

  def remove_player (p)
    @players.reject! {|x| x == p }
  end

  def is_quizmaster? (p)
    self.quizmaster == p
  end

  def is_contestant? (p)
    contestants.include? (p)
  end

  def output_to_all (message)
    @players.each {|x| x.output (message) }
  end

  def output_to_players (message)
    contestants.each {|x| x.output (message) }
  end

  def output_to_quizmaster (message)
    self.quizmaster.output (message)
  end

  def ask (question)
    @question = question
    self.output_to_all("Question #{@round}: #{@question}" )
  end

  def player_list ()
    buffer = Array["^W#{quizmaster.name}^n: Thy Quiz Master"]
    buffer = buffer + contestants.collect {|x| "#{x.name}: #{x.score} point#{ if x.score != 1 then "s" end }" }
    buffer.join("\n")
  end

  def round_scores ()
    buffer = Array.new()
    buffer << "^WQuestion #{@round}: ^n#{@question}"
    buffer << "^WAnswer: ^n#{@answer}"
    answers = contestants.select{ |p| p.answered? }
    correct = answers.select{ |p| p.correct? }
    wrong = answers.reject{ |p| p.correct? }
    correct.each do |p|
      buffer << "^W#{p.name}: ^n#{p.answer} ^GCorrect!^n"
    end
    wrong.each do |p|
      buffer << "^W#{p.name}: ^n#{p.answer} ^RWrong!^n"
    end
    return buffer
  end

  def new_round()
    @round += 1
    correct = contestants.select{|p| p.correct?}
    wrong = contestants.select{|p| p.wrong?}
    correct.each do |p|
      p.score += 1
      p.mark = nil
    end
    wrong.each do |p|
      p.mark = nil
    end
    players.each {|p| p.answer = nil }
  end

  def winners ()
    if contestants.nil?
      return nil
    else
      winners = Array.new
      highest = 0
      contestants.each do |x|
        if x.score > highest
	  winners = Array.new(1, x.name)
          highest = x.score
        elsif x.score == highest
          winners << x.name
	end
      end
      return winners
    end
  end
end # quiz

module Commands
  define_command 'quiz' do |message|
    game = Quiz.find()
    if !game.nil?
      p = game.player(self)
    end
    if game.nil?
      output "No quiz is running."
    elsif p.nil? or game.is_contestant?(p)
      output box("Thy Quizzers", game.player_list().wrap(75) )
    elsif game.is_quizmaster?(p)
      output box("Round #{game.round} answers so far", game.round_scores.join("\n").wrap(75) )
    end
  end

  define_alias 'quiz', 'q'

  ## quiz info

  define_command 'quiz who' do |message|
    game = Quiz.find()
    if game.nil?
      output "No quiz is running."
    else
      output box("Thy Quizzers", game.player_list().wrap(75) )
    end
  end

  define_alias 'quiz who', 'qwho'

  ## starting and ending quizzes

  define_command 'quiz start' do
    game = Quiz.find()
    if !game.nil?
      p = game.player(self)
      if p.nil?
        output "#{game.quizmaster.name} is already running a quiz. Use quiz join to join in."
      elsif game.is_quizmaster? (p)
        output "You are the quizmaster. Ask questions using 'quiz ask'"
      elsif game.is_contestant?(p)
        output "You're already playing the quiz."
      end
    else
      Quiz.new(self, 0)
      output_to_all "^Y\u{2192}^n #{name} is running a quiz. Type ^Wquiz join^n to join in!"
    end
  end

  define_command 'quiz finish' do
    game = Quiz.find()
    if !game.nil?
      p = game.player(self)
    end
    if game.nil?
      output "No quiz is running."
    elsif p.nil?
      output "You're not in the quiz."
    elsif game.is_contestant? (p)
      output "You are not the quizmaster. To leave the quiz, use ^wquiz leave^n."
    else
      if game.round != 0
        game.output_to_players(box("Round #{game.round} Answers", game.round_scores.join("\n").wrap(75)))
      end
      game.new_round()
      if game.contestants.nil?
        self.quizmaster.output "The quiz is over."
      else
        winners = game.winners()
        if !winners.nil? and winners.length > 0
          output_to_all "^Y\u{2192}^n #{commas_and(winners)} won the quiz!"
        else
          game.output_to_all "^Y\u{2192}^n The quiz is over."
        end
      end
      game.destroy 
    end
  end

  # joining and leaving quizzes

  define_command 'quiz join' do
    game = Quiz.find()
    if !game.nil?
      p = game.player(self)
    end
    if game.nil?
      output "No quiz is running."
    elsif p.nil?
      game.add_player(self)
      game.output_to_all ("^Y\u{2192}^n #{name} joined the quiz!")
      if game.question.nil?
	output "^Y\u{2192}^n The quiz has not yet begun."
      else
	output "^Y\u{2192}^n Question #{game.round}: #{game.question}"
      end
    elsif game.is_quizmaster? (p)
      output "You are the quizmaster."
    elsif game.is_contestant?(p)
      output "You're already playing Quiz."
    end
  end
  
  define_alias 'quiz join', 'join quiz'

  define_command 'quiz leave' do
    game = Quiz.find()
    if !game.nil?
      p = game.player(self)
    end
    if game.nil?
      execute_parent_command('quiz')
    elsif p.nil?
      output "You're not playing the quiz."
    elsif game.is_quizmaster? (p)
      output "You are the quizmaster. (To finish the quiz, use ^yquiz finish^n.)"
    else
      game.remove_player(p)
      output "^Y\u{2192}^n You leave the quiz."
      game.output_to_all ("^Y\u{2192}^n #{name} left the quiz.")
    end
  end

  define_alias 'quiz leave', 'leave quiz'

  # question asking

  define_command 'quiz ask' do |message|
    game = Quiz.find()
    if !game.nil?
      p = game.player(self)
    end
    if game.nil?
      execute_parent_command('quiz')
    elsif p.nil?
      output "You're not playing the quiz."
    elsif game.is_contestant? (p)
      if game.question.nil?
        output "No question has been asked yet this round."
      else
	output "Question #{game.round}: #{game.question}"
      end
    elsif message.blank?
      output "Format: quiz ask <question>"
    else
      if game.round != 0
        game.output_to_players(box("Round #{game.round} Answers", game.round_scores.join("\n").wrap(75)))
      end
      game.new_round()
      game.ask (message)
      send_prompt "What is the answer? > "
      self.handler = :quiz_set_answer
    end
  end

  # question answering 
 
  define_command 'quiz answer' do |message|
    game = Quiz.find()
    if !game.nil?
      p = game.player(self)
    end
    if game.nil?
      execute_parent_command('quiz')
    elsif p.nil?
      output "You're not in the quiz. Use ^yquiz join^n to join in."
    elsif game.question.nil?
      output "The quiz hasn't started yet."
    elsif message.blank?
      output "Format: quiz answer <your answer>"
    elsif game.is_quizmaster? (p)
      game.answer = message
      output "Answer changed."
    else
      if !p.answer.nil?
        if p.mark.nil? 
          p.answer = message
          output "You change your answer to \'#{message}\'"
          game.quizmaster.output "^W\u{2192}^n #{p.name} changes their answer to \'#{message}\'"
	else
          output "It's too late to change your answer now."
	  game.quizmaster.output "^W\u{2192}^n #{p.name} tried to change their answer. (You could unset it for them if you like.)"
	end
      else
        p.answer = message
	if message.downcase == game.answer.downcase
          p.mark = :tick
	end
        output "You answer \'#{message}\'"
	if p.mark != :tick
          game.quizmaster.output "^Y\u{2192}^n #{p.name} answers \'#{message}\'"
        else
          game.quizmaster.output "^Y\u{2192}^n #{p.name} answers \'#{message}\' (Automatically marked ^Gcorrect^n!)"
        end
	if game.contestants.reject{|x| x.answered?}.empty?
          game.quizmaster.output "^Y\u{2192}^n All players have answered."
	end
      end
    end
  end

  ## question marking

  define_command 'quiz tick' do |message|
    game = Quiz.find()
    if !game.nil?
      p = game.player(self)
    end
    if game.nil?
      execute_parent_command('quiz')
    elsif p.nil?
      output "You're not in the quiz."
    elsif !game.is_quizmaster? (p)
      output "Only the quizmaster can mark questions"
    elsif message.blank?
      output "Format: quiz tick <player> [<player>...]"
    elsif game.question.nil?
      output "No question has been asked yet."
    else
      hash = game.hash_players(game.contestants)
      marks = Array.new()
      message.split.each do |user|
        u = hash[user.downcase]
        if u.nil? # try partial match
          matches = hash.keys.select {|n| n =~ /^#{Regexp.escape(user.downcase)}/}
          if matches.length == 0
            output "A match for \'#{user}\' could not be found."
          elsif matches.length > 1
            output "Multiple name matches for \'#{user}\': #{matches.join(', ')}."
          else
            u = hash[matches.first]
          end
        end
        if !u.nil?
	  if u.answered?
            u.mark = :tick
	    marks << u.name
	  else
            output "#{u.name} hasn't answered yet!"
          end
        end
      end
      if !marks.empty?
        output "^G\u{2192}^n You give a tick to #{commas_and(marks)}"
      end
    end
  end

  define_alias 'quiz tick', 'tick'

  define_command 'quiz cross' do |message|
    game = Quiz.find()
    if !game.nil?
      p = game.player(self)
    end
    if game.nil?
      execute_parent_command('quiz')
    elsif p.nil?
      output "You're not in the quiz."
    elsif !game.is_quizmaster? (p)
      output "Only the quizmaster can mark questions"
    elsif message.blank?
      output "Format: quiz cross <player> [<player>...] "
    elsif game.question.nil?
      output "No question has been asked yet."
    else
      hash = game.hash_players(game.contestants)
      marks = Array.new()
      message.split.each do |user|
        u = hash[user.downcase]
        if u.nil? # try partial match
          matches = hash.keys.select {|n| n =~ /^#{Regexp.escape(user.downcase)}/}
          if matches.length == 0
            output "A match for \'#{user}\' could not be found."
          elsif matches.length > 1
            output "Multiple name matches for \'#{user}\': #{matches.join(', ')}."
          else
            u = hash[matches.first]
          end
        end
        if !u.nil?
	  if u.answered?
            u.mark = :cross
	    marks << u.name
	  else
            output "#{u.name} hasn't answered yet!"
          end
        end
      end
      if !marks.empty?
        output "^R\u{2192}^n You give a cross to #{self.commas_and(marks)}"
      end
    end
  end

  define_alias 'quiz cross', 'cross'

end

class User
  def quiz_set_answer(answer)
    if answer.blank?
      output "You must set an answer."
      send_prompt "What is the answer? > "
    else
      game=Quiz.find()
      if game.nil?
        output "Thy quiz seems to have disappeared."
      else
        p = game.player(self)
        if game.is_quizmaster?(p)
          game.answer = answer
	  output "Ok."
        else
          output "But you are not the Quizmaster!"
        end
      end
      self.handler = nil
    end
  end
end
