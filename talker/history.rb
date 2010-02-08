# encoding: utf-8
class History
  def initialize
    @history = []
  end
  
  def add(string)
    @history << [Time.now, string]
    @history = @history[-15..-1] if @history.length > 15
  end
  
  def to_s(user)
    @history.map{|t,s| "#{t.strftime(user.get_timestamp_format)}^n #{s}"}.join("\n")
  end
end

