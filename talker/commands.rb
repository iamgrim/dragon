# encoding: utf-8
class Command
  attr_accessor :command_block, :sub_commands
  
  def initialize(name, block)
    @name = name
    @command_block = block
    @sub_commands = {}
  end
  
  def execute(user, body, options={})
    if TalkerBase.instance.on_fire.has_key?(@name)
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
    out = Social.process_string(@text, user, nil, body)
#    if out =~ /%[0-9]/
#      subs = [body] + body.split
#      out = out.gsub(/%([0-9])/) {|s|subs[$1.to_i] || ""}
#    else
    out = "#{out}#{body.blank? ? '' : ' ' + body}"
#    end
    user.handle_input(out)
  end
end
