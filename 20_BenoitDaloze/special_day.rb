class SpecialDay
  def initialize(day, opening, closing)
    @day = BusinessHours.parse_day(day)
    @opening, @closing = BusinessHours.parse_hour(opening), BusinessHours.parse_hour(closing)
  end

  def time_range(day)
    if @day.same_day? day
      TimeRange.new @opening..@closing, @day
    else
      BusinessHours::ALL_DAY
    end
  end
end
