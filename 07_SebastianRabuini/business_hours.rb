require 'time'
require 'date'

class BusinessHours
  DAYS = Time::RFC2822_DAY_NAME.map {|day| day.downcase.to_sym}
  A_DAY = 60*60*24

  def initialize(open, close)
    @open, @close = open, close
    @closed_days, @closed_dates, @updated_days, @updated_dates = [], [], {}, {}
  end

  def update(day_or_date, open, close)
    hours = { :open => open, :close => close }
    if is_a_day?(day_or_date)
      @updated_days[day_or_date] = hours
    else
      @updated_dates[ymd_date(Time.parse(day_or_date))] = hours
    end
  end

  def closed(*days_or_dates)
    days_or_dates.each do |day_or_date|
      if is_a_day?(day_or_date)
        @closed_days << day_or_date
      else
        @closed_dates << ymd_date(Time.parse(day_or_date))
      end
    end
  end

  def calculate_deadline(interval, starting)
    starting_time = Time.parse(starting)
    
    if business_day?(starting_time)
      business_hours = day_range(starting_time)
      if business_hours.include?(starting_time)
        start_time = starting_time
      else
        if starting_time < business_hours.min
          start_time = business_hours.min
        else
          start_time = day_range(next_business_day(starting_time)).min
        end
      end
    else
      business_hours = day_range(next_business_day(starting_time))
      start_time = business_hours.min
    end
    
    end_time = start_time + interval

    until business_hours.include?(end_time)
      unallocated_time = end_time - business_hours.max
      business_hours = day_range(next_business_day(end_time))
      end_time = business_hours.min + unallocated_time
    end
    return end_time
  end

private

  def day_range(time)
    if updated?(time)
      open, close = updated(time)
    else
      open, close = @open, @close
    end
    return Time.parse("#{ymd_date(time)} #{open}")..Time.parse("#{ymd_date(time)} #{close}")
  end
  
  def business_day?(time)
    !(@closed_dates.include?(ymd_date(time)) || @closed_days.include?(DAYS[time.wday]))
  end
  
  def next_business_day(time)
    time += A_DAY
    while !business_day?(time)
      time += A_DAY
    end
    return time
  end
  
  def updated?(time)
    @updated_days.include?(DAYS[time.wday]) || @updated_dates.include?(ymd_date(time))
  end
  
  def updated_day?(time)
    @updated_days.include?(DAYS[time.wday])
  end

  def updated_date?(time)
    @updated_dates.include?(ymd_date(time))
  end
  
  def updated(time)
    if updated_date?(time)
      date_key = ymd_date(time)
      return [@updated_dates[date_key][:open],@updated_dates[date_key][:close]]
    else
      if updated_day?(time)
        day_key = DAYS[time.wday]
        return [@updated_days[day_key][:open], @updated_days[day_key][:close]]
      else
        return nil
      end
    end
  end

  def ymd_date(time)
    time.strftime("%Y-%m-%d")
  end
  
  def is_a_day?(day_or_date)
    DAYS.include?(day_or_date)
  end
end