# encoding: utf-8
module Talker
  define_command 'staff' do
    buffer = ""
    (0..5).each do |i|
      rank = 6 - i
      staff_at_rank = commas_and(all_users.values.select{|u| u.rank == rank}.map {|u| u.name})
      buffer += sprintf("#{User::RANK_COLOUR[rank]}%8.8s ^n: %-64.64s\n", User::RANK[rank], staff_at_rank)
    end
    output box("Nobility", buffer)
  end

  define_command 'promote' do
    if rank > 5
      output "You are already a ^RKing^n!"
    elsif !can_afford_promotion?
      output "You need #{next_rank_cost} drogna for the next rank.^n"
    else
      promote!
      output "Thank you for the donation!"
      output_to_all "^G\u{2192} ^n#{name} has been promoted to a #{rank_name_with_colour}"
      save
    end
  end

  define_command 'demote' do
    if rank <= 0
      output "You can't go lower than Pheasant!"
    else
      demote!
      output "You are demoted."
      save
    end
  end

  define_command 'su' do |message|
    if rank > 0
      if message.blank?
        output "Format: su <message>"
      else
        c = Talker.command_list['tell']
        c.execute(self, "#{connected_users.values.select{|u| u.rank > 0}.map{|u|u.name}.join(',')} ^Y<SU> #{message}^n") if c
      end
    else
      output "You are not prestigious enough to use that."
    end
  end

  define_command 'au' do |message|
    if rank > 3
      if message.blank?
        output "Format: au <message>"
      else
        c = Talker.command_list['tell']
        c.execute(self, "#{connected_users.values.select{|u| u.rank > 3}.map{|u|u.name}.join(',')} ^R<Admin> #{message}^n") if c
      end
    else
      output "You are not prestigious enough to use that."
    end
  end
  
  define_command 'offduty' do |message|
    if rank > 0
      if !onduty
        output "You are already off duty."
      else
        self.onduty = false
        output_to_all "^R\u{2192}^n #{name} goes off duty."
        save
      end
    else
      output "You are not prestigious enough to use that."
    end
  end

  define_command 'onduty' do |message|
    if rank > 0
      if onduty
        output "You are already on duty."
      else
        self.onduty = true
        output_to_all "^G\u{2192}^n #{name} returns to duty."
        save
      end
    else
      output "You are not prestigious enough to use that."
    end
  end
  
  define_command 'drag' do |target_name|
    if rank > 1
      if target_name.blank?
        output "Format: drag <user>"
      else
        target = find_user(target_name)
        if target
          target.gender = target.gender == :male ? :female : :male
          target.save
          output_to_all "^R\u{2192}^n #{name} has dragged #{target.name}! Their gender is now #{target.gender}" 
        end
      end
    else
      output "You are not prestigious enough to use drag, it requires Knight or above."
    end
  end

  define_command 'brum' do |target_name|
    if rank > 1
      if target_name.blank?
        output "Format: brum <user>"
      else
        target = find_user(target_name)
        if target
          if target.wossed
           output "Jonathan Woss is not a brummy!"
          else
            if target.brummed.nil?
              target.brummed = Time.now + 600
              output_to_all "^G\u{2192}^n #{name} turns #{target.name} into a Brummy! Bostin mate!"
              target.save
            else
              target.brummed = nil
              target.output "You speak English again."
              output "#{target.name} will speak English again."
              target.save
            end
          end
        end
      end
    else
      output "You are not prestigious enough to use brum, it requires Knight or above."
    end
  end

  define_command 'wossy' do |target_name|
    if rank > 1
      if target_name.blank?
        output "Format: wossy <user>"
      else
        target = find_user(target_name)
        if target
          if target.brummed
            output "You cannot turn a Brummy into Jonathan Ross!"
          else
            if target.wossed.nil?
              target.wossed = Time.now + 600
              output_to_all "^G\u{2192}^n #{name} turns #{target.name} into Jonathan Woss!"
              target.save
            else
              target.output "You speak English again."
              output "#{target.name} will speak English again."
              target.wossed = nil
              target.save
            end
          end
        end
      end
    else
      output "You are not prestigious enough to use wossy, it requires Knight or above."
    end
  end

  define_command 'sneeze' do |target_name|
    if rank > 2
      if target_name.blank?
        output "Format: sneeze <user>"
      else
        target = find_user(target_name)
        if target
          target.sneezed_on = true
          output_to_all sneeze_string "^G\u{2192}^n #{name} sneezes all over #{target.name}!! ACHOOOOOO!!!"
          target.save
        end
      end
    else
      output "You are not prestigious enough to use sneeze, it requires Baron or above."
    end
  end

  define_command 'lsu' do |message|
    active_staff = active_users.select {|u| u.rank > 0 && u.onduty}
    if active_staff.empty?
      output "There are no active nobs, the world is currently in anarchy."
    else
      buffer = "^G                              ,     \\    /      ,      
    Nobel Staff Memberse     / \\    )\\__/(     / \\     Of Dragon Whirlde
                            /   \\  (_\\  /_)   /   \\\n^P\u{250C}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}^G/^P\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}^G\\^P\u{2500}\u{2500}^G\\^R@  @^G/^P\u{2500}\u{2500}\u{2500}^G/^P\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}^G\\^P\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2510}
^P\u{2502}                                   ^G|\\../|                                    ^P\u{2502}
^P\u{2502}                                    ^G\\VV/                                     ^P\u{2502}\n"

      len = active_staff.map {|u|u.name.length}.max    
      buffer += active_staff.map { |u| 
        s = sprintf("%#{len}.#{len}s  #{User::RANK_COLOUR[u.rank]}%8.8s   ^n#{time_in_words(u.idle_time)} idle", u.name, User::RANK[u.rank]) 
        width = 75 + s.length - colourise(s, false).length
        sprintf("^P\u{2502}^n %-#{width}.#{width}s ^P\u{2502}^n\n", s)
        }.join("\n")

      buffer += "^P\u{2514}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2518}
                       ^G|    /\\ /      \\\\       \\ /\\    |
                       |  /   V        ))       V   \\  |
                       |/     `       //        '     \\|
                       `              V                '^n"
      output buffer
    end
  end

end