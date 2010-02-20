# encoding: utf-8
module Commands
  define_command 'staff' do
    buffer = ""
    (0..5).each do |i|
      rank = 6 - i
      staff_at_rank = commas_and(all_users.values.select{|u| u.rank == rank}.map {|u| u.name})
      buffer += sprintf("#{User::RANK_COLOUR[rank]}%8.8s ^n: %-64.64s\n", User::RANK[rank], staff_at_rank)
    end
    output box("Staff", buffer)
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

end