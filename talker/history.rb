# encoding: utf-8
class History
  def initialize
    @history = []
  end
  
  def add(string)
    @history << [Time.now, string]
    @history = @history[-15..-1] if @history.length > 15
  end
  
  def to_s(timeprefix="^c%H:%M^n", timezone)
    @history.map{|t,s| "#{timezone.strftime(timeprefix, t)}^n #{s}"}.join("\n")
  end
end

