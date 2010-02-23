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
  
  define_command 'memo list' do
    if memos.length > 0
      i = 0
      output box("You have #{memos.length} unread memos", 
        "     ^WFrom                                                              Sent^n\n" +
        memos.map {|memo| sprintf("%-4.4s ^W%-15.15s ^c%54.54s^n", "(#{i+=1})", memo.from.name, get_timezone.strftime("%l:%M %p, %A %d %B %Y", memo.sent))}.join("\n"))
    else
      output "You don't have any unread memos."
    end
  end
  define_alias 'memo list', 'memos'
  
  define_command 'memo read' do |message|
    if message.blank?
      output "Format: memo read <user|number>"
    else
      if message =~ /[0-9]+/
        i = message.to_i - 1
        if i < 0 || i > memos.length - 1
          output "You don't have a memo corresponding to that number"
        else
          memo = memos[i]
          memos.delete_at(i)
          output memo.read
        end
      else
        i = 0
        while i < memos.length do
          if memos[i].from.name == find_user(message).name
            memo = memos[i]
            break
          end
          i += 1
        end
        if !memo.nil?
          memos.delete_at(i)
          output memo.read
        else
          output "You don't have any memos from that person."
        end
      end
    end
  end
  define_alias 'memo read', 'read'
  
  define_command 'memo' do |message|
    (target, message) = get_arguments(message, 2)
    if message.blank?
      output "Format: memo [<user(s)> <message>|list|read <user|number>]"
    else
      users = find_users(target)
      if !users.nil?
        users.each do |user|
          user.send_memo(self, message)
          if user.logged_in?
            user.output "#{self.name} sent you a new memo."
          end
        end
        output "Sent memo to #{commas_and(users.map {|user| user.name})}."
      end
    end
  end
  
end