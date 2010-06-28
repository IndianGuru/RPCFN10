require 'time'

class BusinessHours
  def initialize opening, closing
    @hours = Hash.new( [opening, Time.parse(closing)-Time.parse(opening)] )
  end

  def calculate_deadline interval, drop_off
    target = seconds_before_closing( time = Time.parse(drop_off) )

    target += open_hours( time += 86400 ).last while target < interval

    time_after_opening( time, interval - (target - open_hours(time).last) )
  end

  def closed  *dates
    dates.each { |date| @hours[date] = ["12:00 PM", 0] } 
  end

  def update day, opening, closing
    @hours[day] = [ opening, Time.parse(closing)-Time.parse(opening) ]
  end

  private

  def time_to_day time
    Time::RFC2822_DAY_NAME[string_or_time(time).wday].downcase.to_sym
  end

  def time_to_date time
    string_or_time(time).strftime("%b %d, %Y")
  end

  def string_or_time time
    time.is_a?(String) ? Time.parse(time) : time 
  end
  
  def open_hours time
    @hours.fetch(time_to_date time) { @hours[time_to_day time] }
  end

  def seconds_before_closing time
    open_hours(time).last -  (time - Time.parse(open_hours(time).first, time) )
  end

  def time_after_opening time, interval
    Time.parse(open_hours(time).first, time) + interval
  end
end