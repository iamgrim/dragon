# encoding: utf-8
module Commands
  define_command 'say' do |message|
    if message.blank?
      output "Format: say <message>"
    else
      channel_output "#{cname} says \u{2018}#{message}^n\u{2019}"
    end
  end
  define_alias 'say', '`', '\'', '\"'
  
  define_command 'emote' do |message|
    if message.blank?
      output "Format: emote <message>"
    else
      channel_output "#{cname} #{message}^n"
    end
  end
  define_alias 'emote', ';', ':', 'emtoe', 'emoet', 'emotes', 'me'

  define_command 'echo' do |message|
    if message.blank?
      output "Format: echo <message>"
    else
      channel_output "[#{cname}] #{message}^n"
    end
  end
  define_alias 'echo', '+'
  
  define_command 'tell' do |message|
    (target_name, message) = get_arguments(message, 2)
    
    if message.blank?
      output "Format: tell <user(s)> <message>"
    else
      if multi_target?(target_name)
        m = find_multi(target_name)
        m.tell(self, message) if m
      else
        target = find_connected_user(target_name)
        if target
          if target.is_ignoring?(self)
            output "#{target.name} is ignoring you."
          else
            format = if message =~ /\?$/
              ['ask', 'of ']
            elsif message =~ /!$/
              ['exclaim', 'to ']
            else
              ['tell', '']
            end
            target.output_with_history "^L> #{cname}^L #{format[0]}s #{format[1]}you \u{2018}#{message}^L\u{2019}^n"
            output_with_history "^L> You #{format[0]} #{format[1]}#{target.cname}^L \u{2018}#{message}^L\u{2019}^n"
            output_inactive_message(target)
          end
        end
      end
    end
  end
  define_alias 'tell', '.', 'rsay'
  
  define_command 'pemote' do |message|
    (target_name, message) = get_arguments(message, 2)
    
    if message.blank?
      output "Format: pemote <user(s)> <message>"
    else
      if multi_target?(target_name)
        m = find_multi(target_name)
        m.pemote(self, message) if m
      else
        target = find_connected_user(target_name)
        if target
          if target.is_ignoring?(self)
            output "#{target.name} is ignoring you."
          else
            space = message =~ /^[,']/ ? '' : ' '
            target.output_with_history "^L> #{cname}^L#{space}#{message}^n (to you)^n"
            output_with_history "^L> #{cname}^L#{space}#{message}^n (to #{target.cname}^n)^n"
            output_inactive_message(target)
          end
        end
      end
    end
  end
  define_alias 'pemote', ',', 'remote', '<'
end