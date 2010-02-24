class Memo
  include TalkerUtilities
  
  attr_reader :to
  attr_reader :from
  attr_reader :message
  attr_reader :sent

  def initialize(to, from, message)
    @to = to
    @from = from
    @message = message
    @sent = Time.now
  end
  
  def read
    box_extra("Memo from #{@from.name}", @to.get_timezone.strftime("%l:%M %p, %A %d %B %Y", @sent).strip, @message.wrap(75))
  end
end


