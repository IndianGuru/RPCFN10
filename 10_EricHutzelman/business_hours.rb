# Eric Hutzelman 
# Ruby Challenge 10 (Business Hours)
# http://rubylearning.com/blog/2010/05/25/rpcfn-business-hours-10/
#
# Stores all exception days in a hash (@modified_days) and uses array 
# method to retrieve the time range for any given date.
# Method #calculate_deadline is recursive and applies the available
# seconds for each date to the time required, stepping forward one day
# at a time until the required seconds have been fulfilled.

require 'time'
require 'date'

class Time
  def to_date
    Date.new(year, month, day)
  end
end

class BusinessHours
  
  def initialize(time_in, time_out)
    @default_range = TimeRange.new(time_in, time_out)
    @modified_days = {}
  end
  
  def update(day, time_in, time_out)
    key = day.is_a?(Symbol) ? day : Date.parse(day)
    @modified_days.merge!({key => TimeRange.new(time_in, time_out)})
  end
  
  def closed(*days)
    days.each {|day| update(day, '0:00', '0:00')}      
  end
  
  def [](date)
    day_of_week = date.strftime("%a").downcase.to_sym
    range = @modified_days[date] || @modified_days[day_of_week] || @default_range
    # reset time range dates to match date param
    range.reset_date(date)
    range
  end
  
  def calculate_deadline(seconds, start_time)
    start_time = Time.parse(start_time)
    range = self[start_time.to_date]
    
    if range.applies?(start_time)
      start_time = [start_time, range.start].max
      available_seconds = range.stop - start_time

      return start_time + seconds if available_seconds > seconds
      seconds -= available_seconds
    end
    
    calculate_deadline(seconds, (start_time.to_date + 1).to_s)
  end
    
end

class TimeRange

  def initialize(time_in, time_out)
    @range = Time.parse(time_in)..Time.parse(time_out)
  end

  def reset_date(date)
    @range = Time.local(date.year, date.month, date.day, start.hour, start.min)..
      Time.local(date.year, date.month, date.day, stop.hour, stop.min)    
  end
  
  def applies?(time)
    stop > time
  end
  
  def stop
    @range.end
  end
  
  def start
    @range.begin
  end
      
end
