class Time
  def same_day? time
    year == time.year and month == time.month and day == time.day
  end

  def beginning_of_day
    Time.local year, month, day
  end
end
