class Rule
  def initialize(opening, closing)
    @opening, @closing = BusinessHours.parse_hour(opening), BusinessHours.parse_hour(closing)
  end

  def time_range(day)
    TimeRange.new @opening..@closing
  end
end
