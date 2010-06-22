module Talker
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
  
  def self.command_names
    @visible_command_names.sort {|a,b|a <=> b}
  end
  
  def self.add_command(name, command)
    @command_list[name] = command
  end
  
  def self.remove_command(name)
    @command_list.delete(name)
  end
end