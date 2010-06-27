class Day
  attr_accessor :open, :closed

  def initialize(open = nil, closed = nil)
    self.set_hours(open, closed)
  end

  def closed?
    self.open == '0:00 AM' && self.closed == '0:00 AM'
  end
  
  def set_hours(open, closed)
    self.open, self.closed = open, closed
  end
end

class Time  
  def parse_time(time)
    Time.parse(self.strftime('%D') << " " << time)
  end
end