#!/usr/bin/env ruby -wKU

require "set"
require "time"

class BusinessHours
  def initialize(default_open_time, default_close_time)
    @default_open_time  = default_open_time
    @default_close_time = default_close_time
    @times_by_day       = { }
    @closed             = Set.new
  end
  
  def update(*args)
    unless args.size >= 3
      raise ArugmentError, "dates and/or weekdays plus open and close required"
    end
    days, open_time, close_time = args[0..-3], args[-2], args[-1]
    days.each do |day|
      @times_by_day[as_day(day)] = [open_time, close_time]
    end
  end
  
  def closed(*days)
    if days.empty?
      raise ArugmentError, "dates and/or weekdays required"
    end
    days.each do |day|
      @closed << as_day(day)
    end
  end
  
  def calculate_deadline(seconds, start_time)
    time = Time.parse(start_time)
    loop do
      open, close = open_and_close(time)
      if open and close
        if time < close
          time = open if time < open
          if (left_in_day = close - time) > seconds
            return time + seconds
          else
            seconds -= left_in_day
          end
        end
      end
      time = next_day(time)
    end
  end
  
  private
  
  def as_day(day)
    case day
    when Time   then Time.local(day.year, day.month, day.day)
    when Symbol then day
    else             Time.parse(day)
    end
  end
  
  def open_and_close(time)
    day = as_day(time)
    return if @closed.include? day
    open_and_close = @times_by_day[day]                                || 
                     @times_by_day[day.strftime("%a").downcase.to_sym] ||
                     [@default_open_time, @default_close_time]
    open_and_close.map { |t| Time.parse("#{day.strftime('%b %d, %Y')} #{t}") }
  end
  
  def next_day(time)
    (23..25).each do |offset|
      if (new_time = time + offset * 60 * 60).day != time.day
        return as_day(new_time)
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  hours = BusinessHours.new("9:00 AM", "3:00 PM")

  hours.update :fri, "10:00 AM", "5:00 PM"
  hours.update "Dec 24, 2010", "8:00 AM", "1:00 PM"
  hours.closed :sun, :wed, "Dec 25, 2010"

  p hours.calculate_deadline(2*60*60, "Jun 7, 2010 9:10 AM")
  # => Mon Jun 07 11:10:00 2010
  p hours.calculate_deadline(15*60, "Jun 8, 2010 2:48 PM")
  # => Thu Jun 10 09:03:00 2010
  p hours.calculate_deadline(7*60*60, "Dec 24, 2010 6:45 AM")
  # => Mon Dec 27 11:00:00 2010
end
