# encoding: utf-8
module Commands
  define_command 'reboot', :invisible => true do
    if developer?
      reboot
    else
      output "No permission."
    end
  end

  define_command 'shutdown', :invisible => true do |message|
    if developer?
      if message.blank?
        output "Format: shutdown <message>"
      else
        output_to_all "^Y=> Shutting Down: #{message}^n"
        shutdown
      end
    else
      output "No permission."
    end
  end
  
  define_command 'multis', :invisible => true do
    output box("Multis", Multi.view)
  end

#  define_command 'reset_password' do |target_name|
#    if developer?
#      if target_name.blank?
#        output "Format: reset_password <user name>"
#      else
#        u = find_user(target_name)
#        if u
#          u.crypted_password = "elZ0lon/B9mUI" # changeme
#          u.save
#          output "Password reset for #{u.name}."
#        end
#      end
#    else
#      output "No permission."
#    end
#  end

  define_command 'show_changes', :invisible => true do
    if developer?
      output_to_all box("Thy scribes hath made thy following changeth", get_text("changes"))
    else
      output "No permission."
    end
  end
  
#  define_command 'dectest' do
#    output "\033(0 k l m n o p q r s t u v w x }\033(B"
#  end
end