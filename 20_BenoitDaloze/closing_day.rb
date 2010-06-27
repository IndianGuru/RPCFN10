class ClosingDay
  def initialize(day)
    @day = BusinessHours.parse_day(day)
  end

  def time_range(day)
    if @day.same_day? day
      BusinessHours::NO_DAY
    else
      BusinessHours::ALL_DAY
    end
  end
end
