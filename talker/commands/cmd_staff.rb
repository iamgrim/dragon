# encoding: utf-8
module Commands
  define_command 'staff' do
    buffer = ""
    (0..5).each do |i|
      rank = 6 - i
      staff_at_rank = commas_and(all_users.values.select{|u| u.rank == rank}.map {|u| u.name})
      buffer += sprintf("#{User::RANK_COLOUR[rank]}%8.8s ^n: %-64.64s\n", User::RANK[rank], staff_at_rank)
    end
    output box("Knobs", buffer)
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
        c = Commands.lookup('tell')
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
        c = Commands.lookup('tell')
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
          target.output "You have been dragged by #{name}! Your gender is now #{target.gender}"
          output "You have dragged #{target.name}! Their gender is now #{target.gender}" 
        end
      end
    else
      output "You are not prestigious enough to use drag, it requires Knight or above."
    end
  end

  define_command 'lsu' do |message|
    active_staff = active_users.select {|u| u.rank > 0 && u.onduty}
    if active_staff.empty?
      output "There are no active knobs, the world is currently in anarchy."
    else
      len = active_staff.map {|u|u.name.length}.max    
      output box("Active Knobs (Members of the Nobility)", active_staff.map { |u| sprintf("%#{len}.#{len}s  #{User::RANK_COLOUR[u.rank]}%8.8s   ^n#{time_in_words(u.idle_time)} idle", u.name, User::RANK[u.rank]) }.join("\n"))
    end
  end

end