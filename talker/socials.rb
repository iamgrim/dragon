# encoding: utf-8
class Social
  @socials = {}

  attr_accessor :name, :creator, :target, :notarget
  
  def initialize(name, creator, notarget, target)
    @name     = name
    @creator  = creator
    @notarget = notarget
    @target   = target
  end
  
  def created_by?(user)
    user.lower_name == creator.downcase
  end
  
  def supports_targeted?
    !@target.blank?
  end
  
  def supports_untargeted?
    !@notarget.blank?
  end

  def requires_target?
    supports_targeted? && !supports_untargeted?
  end
  
  def execute(user, body)
    body ||= ""
    text = nil
    
    if supports_targeted?
      (target_name, message) = body.split(' ', 2)
      target = user.find_connected_user(target_name, :silent => true)
      if target
        text = @target
        body = message || ""
      elsif supports_untargeted?
        text = @notarget
      else
        user.output "Format: #{@name} <user>"
      end
    else
      text = @notarget
      target = nil
    end
    
    if !text.blank?
      if text =~ /<([M|m]essage|S)>/ && body.blank?
        user.output "Format: #{@name} <message>"
      else
        user.channel_output "#{user.cname} #{Social.process_dynatext(Social.process_randoms(text), user, target, body)}^n".gsub("\r\n", "")
      end
    else
      user.output "Sorry, the social is down for maintenance."
    end
  end
  
  def self.process_randoms(text)
    stack          = []
    stored_string  = ""
    random_choices = []

    scanner = StringScanner.new(text)
    while match = scanner.scan_until(/[\{\}\|]|\[(one of|or|at random)\]/)
      stored_string << match.slice(0, match.length - scanner.matched_size)
      case scanner.matched
      when "{", "[one of]"
        stack.push([random_choices, stored_string])
        random_choices = []
        stored_string  = ""
      when "|", "[or]"
        if stack.empty?
          stored_string << "|"
        else
          random_choices.push(stored_string)
          stored_string = ""
        end
      when "}", "[at random]"
        unless stack.empty?
          random_choices.push(stored_string)
          selected_choice = random_choices[rand(random_choices.length)]
          (random_choices, stored_string) = stack.pop
          stored_string << selected_choice
        end
      end
    end
    stored_string << scanner.rest if scanner.rest?
    stored_string
  end
  
  def self.process_dynatext(text, from, to, message)
    text = text.gsub(/<(message|S)>/i, message)

    stored_string  = ""
    scanner = StringScanner.new(text)
    while match = scanner.scan_until(/<(T|S|U)[a-zA-Z]*:([a-zA-Z]+)>/)
      stored_string << match.slice(0, match.length - scanner.matched_size)
      case scanner[1].upcase
      when "S", "U"
        stored_string << process_dynatext_part(from, scanner[2])
      when "T"
        stored_string << (to.nil? ? "" : process_dynatext_part(to, scanner[2]))
      end
    end
    stored_string << scanner.rest if scanner.rest?
    stored_string
  end
  
  GENDER_WORDS = {
    "heshe" => {:male => "he", :female => "she"},
    "hisher" => {:male => "his", :female => "her"},
    "himher" => {:male => "him", :female => "her"},
    "hishers" => {:male => "his", :female => "hers"},
    "malefemale" => {:male => "male", :female => "female"},
  }
  
  def self.process_dynatext_part(user, type)
    gender = user.gender || :female
  
    if type == "name"
      user.name
    elsif type == "drogna"
      "#{user.money}\u{20ab}"
    elsif type == "rank"
      user.rank_name_with_colour
    elsif GENDER_WORDS.include?(type)
      GENDER_WORDS[type][gender]
    else
      ""
    end
  end
 
  def self.process_string(text, from, to, message)
    Social.process_dynatext(Social.process_randoms(text), from, to, message)
  end
  
  def examine
    buffer =  "^LCreator^n\n#{@creator.blank? ? 'Unknown' : @creator}\n" 
    buffer += "^LUntargeted^n\n#{@notarget.gsub(/\^/, '^^')}\n" if !@notarget.blank?
    buffer += "^LTargeted^n\n#{@target.gsub(/\^/, '^^')}\n" if !@target.blank?
    buffer
  end
  
  def self.import_all
    Dir["import/socials/*"].each do |file_name|
      Social.import(file_name)
    end    
  end
  
  def self.import(file_name)
    name = File.basename(file_name)

    s = {}
    current_token = nil
    File.foreach(file_name) do |line|
      if line =~ /^[a-z\-]+:/
        (token, value) = line.split(':', 2)
        current_token = token.strip
        s[current_token] = value.strip.gsub('!newline!', "\n") if current_token && value
      else
        value = line
        s[current_token] += value.strip.gsub('!newline!', "\n") if s.has_key?(current_token)
      end 
    end

    lower_name = name.downcase
    social = @socials[lower_name] = Social.new(lower_name, s['creator'] || "", s['nt-u'] || "", s['ut-u'] || "")
    c = Commands.lookup(lower_name)
    Commands.add_command(lower_name, social) unless c && c.class == Command
    social
  end
  
  def delete
    lower_name = name.downcase
    data_file_name = "import/socials/#{lower_name}"
    File.delete(data_file_name) if FileTest.exist?(data_file_name)
    Social.socials.delete(lower_name)
    Commands.remove_command(lower_name)
  end
  
  def self.socials
    @socials
  end
  
  def self.names
    @socials.keys.sort {|a,b|a <=> b}
  end
  
  def self.socials_by(u)
    @socials.values.select{|s|s.creator == u.lower_name}
  end
end

module Commands
  define_command 'social pull' do |social_name|
    if social_name.blank?
      output "Format: social pull <social name>"
    elsif valid_name?(social_name, :allow_bad_words => true)
      social_name.downcase!
      buffer = ""
      creator = ""
      begin
      result = open("http://wooooooooooooooy.com/socials/#{social_name}.txt") do |f|
        f.each_line do |line|
          buffer += line
          if line =~ /^creator/
            (token, value) = line.split(':', 2)
            creator = value.strip.downcase
          end
        end
      end
      rescue Exception => e
        if e.class == OpenURI::HTTPError && e.io.status[0] == "404"
          output "'#{social_name}' isn't on wooooooooooooooy.com."
        else
          debug_message "#{name} failed to pull social '#{social_name}': #{e}"
          output "Sorry, an error occurred when trying to pull the social. Please try again later."
        end
      else
        if Talker::LIVE and creator != lower_name
          output "Sorry, only the creator can pull the social."
        else
          update = Social.socials.has_key?(social_name)

          File.open("import/socials/#{social_name}", "w") do |file|
            file.puts buffer
          end
          Social.import("import/socials/#{social_name}")
          if update
            debug_message "Social '#{social_name}' updated by #{name}"
            output "The social has been updated."
          else
            output_to_all "^Y\u{2192}^n #{cname} creates the ^L#{social_name}^n social"
          end
        end
      end
    end
  end

  define_command 'social liquidate' do |social_name|
    if social_name.blank?
      output "Format: social liquidate <social name>"
    elsif social = find_social(social_name)
      if social.created_by?(self) || developer?
        output "You have liquidated the social '#{social.name}'"
        social.delete
      else
        output "You need a full controlling share to liquidate the asset."
      end
    end
  end

  define_command 'socials' do |user_name|
    if user_name.blank?
      output box("Actions thoust can performe", Social.names.join(", ").wrap(75))
    elsif user = find_user(user_name)
      output box("Socials Owned By #{user.name}", Social.socials_by(user).map{|s| s.name}.join(", ").wrap(75))
    end
  end
  
  define_alias 'sing', ')'
  define_alias 'think', '~'
end