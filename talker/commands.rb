# encoding: utf-8
class Command
  attr_accessor :command_block, :sub_commands
  
  def initialize(name, block)
    @name = name
    @command_block = block
    @sub_commands = {}
  end
  
  def execute(user, body, options={})
    if Talker.instance.on_fire.has_key?(@name)
      user.output "^RSorry, that command is currently on fire. Man the fire hose!^n"
    else
      sub_command = nil
      unless options[:sub_command] == false
        if @sub_commands && !body.blank? # try to find and execute a sub-command
          (sub_command_name, body2) = body.split(' ', 2)
  
          sub_command = user.find_with_partial_matching(@sub_commands, sub_command_name, :silent => true)
          sub_command.execute(user, body2) if sub_command
        end
      end

      if sub_command.nil?
        if @command_block.nil? # nothing to run, just list the sub-commands
          if @sub_commands.length > 0
            user.output "The following sub-commands are available:\n" + @sub_commands.keys.map {|sub_name| "  #{@name} ^L#{sub_name}^n"}.join("\n")
          else
            user.debug_message "'#{@name}' has no block to execute."
            user.output "Sorry, #{@name} is down for maintenance."
          end
        else  
          user.instance_exec(body, &@command_block)
        end  
      end
    end
  end
end

class Alias
  attr_reader :name, :text
  def initialize(name, text)
    @name = name
    @text = text
  end
  
  def execute(user, body)
    out = @text
    if out =~ /%[0-9]/
      subs = [body] + body.split
      out = out.gsub(/%([0-9])/) {|s|subs[$1.to_i] || ""}
    else
      out = "#{out}#{body.blank? ? '' : ' ' + body}"
    end
    user.handle_input(Social.process_dynatext(Social.process_randoms(out), self, nil, ""))
  end
end

module Commands
  @command_list = {}
  @visible_command_names = []
  
  def self.define_command(name, options={}, &block)
    if name =~ / / # a sub-command
      (command_name, sub_command_name) = name.split(/ /)
      c = @command_list[command_name]
      if !c
        define_command(command_name)
        c = @command_list[command_name]
      end
      c.sub_commands[sub_command_name] = Command.new(sub_command_name, block)
    else # not a sub-command
      c = @command_list[name]
      if c
        c.command_block = block
      else
        @command_list[name] = Command.new(name, block)
        @visible_command_names << name unless options[:invisible]
      end
    end
  end

  def self.define_alias(alias_text, *alias_names)
    alias_names.each do |alias_name|
      @command_list[alias_name] = Alias.new(alias_name, alias_text)
    end
  end
    
  def self.command_list
    @command_list
  end
  
  def self.names
    @visible_command_names.sort {|a,b|a <=> b}
  end
  
  def self.add_command(name, command)
    @command_list[name] = command
  end
  
  def self.remove_command(name)
    @command_list.delete(name)
  end
  
  def self.lookup(name)
    @command_list[name]
  end
end