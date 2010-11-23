# encoding: utf-8
module Talker
  define_command 'say' do |message|
    if message.blank?
      output "Format: say <message>"
    else
      channel_output "#{cname} says \u{2018}#{change_accent(message)}^n\u{2019}"
    end
  end
  define_alias 'say', '`', '\'', '\"'
  
  define_command 'emote' do |message|
    if message.blank?
      output "Format: emote <message>"
    else
      channel_output "#{cname} #{change_accent(message)}^n"
    end
  end
  define_alias 'emote', ';', ':', 'emtoe', 'emoet', 'emotes', 'me'

  define_command 'echo' do |message|
    if message.blank?
      output "Format: echo <message>"
    else
      channel_output "[#{cname}] #{change_accent(message)}^n"
    end
  end
  define_alias 'echo', '+'
  
  define_command 'tell' do |message|
    (target_name, message) = get_arguments(message, 2)
    
    if message.blank?
      output "Format: tell <user(s)> <message>"
    else
      message = change_accent(message)
      if multi_target?(target_name)
        m = find_multi(target_name)
        m.tell(self, message) if m
      else
        target = find_connected_user(target_name)
        if target
          if target.is_ignoring?(self)
            output "#{target.name} is ignoring you."
          elsif prison && !(on_phone == target.lower_name)
            output "You can not talk to #{target.name} unless you telephone them."
          elsif target.prison && !(target.on_phone == lower_name)
            output "#{target.name} is in prison. You can only talk to them if they telephone you."
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
  define_alias 'tell', '.', 'rsay', '>'
  
  define_command 'pemote' do |message|
    (target_name, message) = get_arguments(message, 2)
    
    if message.blank?
      output "Format: pemote <user(s)> <message>"
    else
      message = change_accent(message)
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
  
#  define_command 'memo list' do |message|
#    if message.blank?
#      if memos.length > 0
#        i = 0
#        output box_extra("You have #{memos.length} unread #{pluralise('memo', memos.length)}", "Sent", memos.map {|memo| sprintf("%-4.4s ^W%-15.15s ^c%54.54s^n", "(#{i+=1})", memo.from.name, get_timezone.strftime("%l:%M %p, %A %d %B %Y", memo.sent))}.join("\n"))
#      else
#        output "You don't have any unread memos."
#      end
#    else
#      user = find_user(message)
#      if !user.nil?
#        output "#{user.name} has #{user.memos.length} unread #{pluralise('memo', user.memos.length)}."
#      end
#    end
#    
#  end
#  define_alias 'memo list', 'memos'
#  
#  define_command 'memo read' do |message|
#    if message.blank?
#      output "Format: memo read <user|number>"
#    else
#      if memos.length == 0
#        output "You don't have any unread memos."
#      else
#        if message =~ /[0-9]+/
#          i = message.to_i - 1
#          if i < 0 || i > memos.length - 1
#            output "You don't have a memo corresponding to that number"
#          else
#            memo = memos[i]
#            memos.delete_at(i)
#            output memo.read
#          end
#        else
#          i = 0
#          while i < memos.length do
#            if memos[i].from.name == find_user(message).name
#              memo = memos[i]
#              break
#            end
#            i += 1
#          end
#          if !memo.nil?
#            memos.delete_at(i)
#            output memo.read
#          else
#            output "You don't have any memos from that person."
#          end
#        end
#      end
#    end
#  end
#  define_alias 'memo read', 'read'
#  
#  define_command 'memo' do |message|
#    (target, message) = get_arguments(message, 2)
#    if message.blank?
#      output "Format: memo [<user(s)> <message>|list|read <user|number>]"
#    else
#      users = find_users(target).uniq
#      if !users.nil?
#        if users.include?(self)
#          output "You can't send a memo to yourself, you idiot."
#        else
#          sent_users = []
#          users.each do |user|
#            if user.is_ignoring?(self)
#              output "#{user.name} is ignoring you."
#            elsif is_ignoring?(user)
#              output "You are supposed to be ignoring #{user.name}. Why would you want to send them a memo?"
#            else
#              user.send_memo(self, message)
#              sent_users.push user
#              if user.logged_in?
#                user.output "#{self.name} sent you a new memo."
#              end  
#            end
#          end
#          output "Sent memo to #{commas_and(sent_users.map {|user| user.name})}." unless sent_users.length == 0  
#        end
#      end
#    end
#  end
  
end