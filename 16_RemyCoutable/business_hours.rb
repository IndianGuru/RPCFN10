# RPCFN #10 - Business Hours by Ryan Bates
# Solution proposed by Rémy Coutable
# (c) Copyright 2010 Rémy Coutable. All Rights Reserved.

require 'date'
require 'time'

class BusinessHours
  
  # Instanciate a new BusinessHours object with normal <tt>opening_hour</tt> and <tt>closing_hour</tt>.
  # 
  # <tt>opening_hour</tt> and <tt>closing_hour</tt> should be strings: <tt>"8:00 AM"</tt> or <tt>"13:00"</tt>
  # 
  # Example:
  #   bh = BusinessHours.new("9:00 AM", "3:00 PM")
  #   bh.to_s #=> [["09:00", "15:00"], {}, []]
  def initialize(opening_hour, closing_hour)
    @normal_hours   = []
    @specific_hours = {}
    @closed_days    = []
    
    @normal_hours << Time.parse(opening_hour).strftime('%H:%M') << Time.parse(closing_hour).strftime('%H:%M')
  end
  
  # Specifies <tt>opening_hour</tt> and the <tt>closing_hour</tt> for a specific <tt>day</tt>.
  # 
  # <tt>days</tt> can take 2 different forms:
  # * generic weekday: <tt>:sun</tt>, <tt>:sunday</tt>, <tt>:mon</tt>, <tt>:monday</tt> ...
  # * precise date: <tt>"Dec 25, 2010"</tt>
  # <tt>opening_hour</tt> and <tt>closing_hour</tt> should be strings: <tt>"8:00 AM"</tt> or <tt>"13:00"</tt>
  # 
  # Example:
  #   bh = BusinessHours.new("9:00 AM", "3:00 PM")
  #   bh.update :friday, "10:00 AM", "5:00 PM"
  #   bh.update :friday, "10:00 AM", "6:00 PM"
  #   bh.to_s #=> [["09:00", "15:00"], { :friday => ["10:00", "18:00"] }, []]
  # <strong>Note:</strong> It is possible to override previously registered special opening hours
  def update(day, opening_hour, closing_hour)
    day = BusinessHours.get_day(day)
    @specific_hours[day] = [Time.parse(opening_hour).strftime('%H:%M'), Time.parse(closing_hour).strftime('%H:%M')] unless day.nil?
  end
  
  # Specifies <tt>days</tt> when the business is closed.
  # 
  # <tt>days</tt> can take 2 different forms:
  # * generic weekday: <tt>:sun</tt>, <tt>:sunday</tt>, <tt>:mon</tt>, <tt>:monday</tt> ...
  # * precise date: <tt>"Dec 25, 2010"</tt>
  # 
  # Example:
  #   bh = BusinessHours.new("9:00 AM", "3:00 PM")
  #   bh.closed :sun, :wed, "Dec 25, 2010", nil, :wed, :foo
  #   bh.to_s #=> [["09:00", "15:00"], {}, [:sunday, :wednesday, "Dec 25, 2010"]]
  # <strong>Note:</strong> <tt>nil</tt> or invalid day identifier are ignored, as well as duplicate closed days
  def closed(*days)
    days.each { |d| @closed_days << BusinessHours.get_day(d) }
    @closed_days.compact!
    @closed_days.uniq!
  end
  
  # Accepts an interval (in seconds) and a starting time (String or Time object) and return a Time object
  # representing the time when a job that last <tt>interval</tt> seconds will be done.
  # 
  # Example:
  #   bh = BusinessHours.new("9:00 AM", "3:00 PM")
  #   bh.update :fri, "10:00 AM", "5:00 PM"
  #   bh.update "Dec 24, 2010", "8:00 AM", "1:00 PM"
  #   bh.closed :sun, :wed, "Dec 25, 2010"
  #   bh.calculate_deadline(7*60*60, "Dec 24, 2010 6:45 AM") #=> Mon Dec 27 11:00:00 0100 2010
  # 
  # Explanation:
  # The time given is 7*60*60 = 25,200 seconds, Dec 24 is open from 8:00 AM to 01:00 PM, that’s 18,000 seconds,
  # so 7,200 seconds are left till the work is done.
  # The next day, Dec 25 is closed, Dec 26 is a wednesday, so it’s also closed.
  # Dec 27 is open from 09:00 AM, adding the 7,200 seconds (2 hours), the job is complete at 11:00 AM.
  def calculate_deadline(interval, starting_time)
    starting_time = Time.parse(starting_time) if starting_time.is_a? String
    
    if open?(starting_time)
      if starting_time.clock_is_before?(Time.parse(opening_hour_on(starting_time)))
        starting_time = Time.parse("#{Date.parse(starting_time.to_s).to_s} #{opening_hour_on(starting_time)}")
      end
      interval -= worked_hours(starting_time)
    end
    
    return starting_time + worked_hours(starting_time) + interval if interval <= 0
    
    calculate_deadline(interval, next_open_time_after(starting_time))
  end
  
  # Return true if the business is closed on the given <tt>time</tt> otherwise false.
  # 
  # Example:
  #   bh = BusinessHours.new("9:00 AM", "3:00 PM")
  #   bh.closed "Dec 25, 2010"
  #   bh.closed?(Time.parse("Dec 25, 2010 11:00 AM")) #=> true
  #   bh.closed?(Time.parse("Dec 24, 2010 11:00 AM")) #=> false
  def closed?(time)
    @closed_days.each { |day| return true if BusinessHours.same_day?(day, time) }
    @specific_hours.each { |day| return true if BusinessHours.same_day?(day, time) && time.clock_is_after?(Time.parse(hours[1])) }
    time.clock_is_after?(Time.parse(@normal_hours[1]))
  end
  
  # Return true if the business is open on the given <tt>time</tt> otherwise false.
  # 
  # Example:
  #   bh = BusinessHours.new("9:00 AM", "3:00 PM")
  #   bh.closed "Dec 25, 2010"
  #   bh.open?(Time.parse("Dec 24, 2010 11:00 AM")) #=> true
  #   bh.open?(Time.parse("Dec 25, 2010 11:00 AM")) #=> false
  def open?(time)
    !closed?(time)
  end
  
  # Return the business' open hours as follow: <tt>[normal_hours(Array), specific_hours(Hash), closed_days(Array)]</tt>.
  # 
  # Example:
  #   bh = BusinessHours.new("9:00 AM", "3:00 PM")
  #   bh.update :friday, "10:00 AM", "5:00 PM"
  #   bh.closed :sun, :wed, "Dec 25, 2010", nil, :wed, :foo
  #   bh.to_s #=> [["09:00", "15:00"], { :friday => ["10:00", "17:00"] }, [:sunday, :wednesday, "Dec 25, 2010"]]
  def to_s
    [@normal_hours, @specific_hours, @closed_days]
  end
  
private
  
  def self.week_days
    [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday]
  end
  
  def self.get_day(dirty_day)
    case dirty_day
    when String
      Time.parse(dirty_day).strftime('%b %d, %Y')
    when Symbol
      BusinessHours.expand_day(dirty_day) || (week_days.include?(dirty_day) ? dirty_day : nil)
    else
      nil
    end
  end
  
  def self.expand_day(day_symbol)
    BusinessHours.week_days.inject({}) { |memo, day| memo[day.to_s[0,3].to_sym] = day; memo }[day_symbol]
  end
  
  def self.same_day?(day, time)
    case day
    when String
      true if Date.parse(day) == Date.new(time.year, time.month, time.day)
    when Symbol
      true if time.wday == week_days.index(day)
    else
      false
    end
  end
  
  def business_hours_on(time)
    [String, Symbol].each do |klass|
      @specific_hours.select{ |k,v| k.is_a? klass }.each { |day, hours| return hours if BusinessHours.same_day?(day, time) }
    end
    @normal_hours
  end
  
  def opening_hour_on(time)
    business_hours_on(time)[0]
  end
  
  def worked_hours(time)
    hours = business_hours_on(time)
    Time.parse(hours[1]) - Time.parse(["#{time.hour}:#{time.min}:#{time.sec}", hours[0]].max)
  end
  
  # Return the next open time, at least on the next day
  def next_open_time_after(time)
    begin
      time = Time.parse("#{Date.new(time.year, time.month, time.day).next.to_s} #{opening_hour_on(time)}")
    end while closed?(time)
    time
  end
  
end

module BusinessHoursModules #:nodoc:
  module TimeExtensions
    # Comparison—Compares time with other_time regarding only their clock (not day, unlike <=>).
    # 
    # Example:
    #   Time.parse("Dec 25, 2010 11:00 AM") <=> Time.parse("Dec 26, 2010 08:00 AM") #=> -1 (Dec 25 is before Dec 26)
    #   Time.parse("Dec 25, 2010 08:00 AM").compare_clock(Time.parse("Dec 26, 2010 11:00 AM")) #=> -1 (08 AM is before 11 AM)
    #   Time.parse("Dec 25, 2010 11:00 AM").compare_clock(Time.parse("Dec 26, 2010 08:00 AM")) #=> 1 (11 AM is after 08 AM)
    #   Time.parse("Dec 25, 2010 11:00 AM").compare_clock(Time.parse("Dec 26, 2010 11:00 AM")) #=> 0 (11 AM is equal to 11 AM)
    def compare_clock(other_time)
      self_clock = Time.parse("#{self.hour}:#{self.min}:#{self.sec}")
      other_clock = Time.parse("#{other_time.hour}:#{other_time.min}:#{other_time.sec}")
      if self_clock < other_clock
        -1
      elsif self_clock > other_clock
        1
      else
        0
      end
    end
    
    # Returns true if <tt>time</tt> is before <tt>other_time</tt>, only regarding their clock. (see <tt>compare_clock</tt>)
    # 
    # Example:
    #   Time.parse("Dec 25, 2010 08:00 AM").clock_is_before?(Time.parse("Dec 26, 2010 11:00 AM")) #=> true
    #   Time.parse("Dec 25, 2010 11:00 AM").clock_is_before?(Time.parse("Dec 26, 2010 08:00 AM")) #=> false
    def clock_is_before?(other_time)
      compare_clock(other_time) == -1
    end
    
    # Returns true if <tt>time</tt> is after <tt>other_time</tt>, only regarding their clock. (see <tt>compare_clock</tt>)
    # 
    # Example:
    #   Time.parse("Dec 25, 2010 11:00 AM").clock_is_after?(Time.parse("Dec 26, 2010 08:00 AM")) #=> true
    #   Time.parse("Dec 25, 2010 08:00 AM").clock_is_after?(Time.parse("Dec 26, 2010 11:00 AM")) #=> false
    def clock_is_after?(other_time)
      compare_clock(other_time) == 1
    end
    
    # Returns true if <tt>time</tt> is equal to <tt>other_time</tt>, only regarding their clock. (see <tt>compare_clock</tt>)
    # 
    # Example:
    #   Time.parse("Dec 25, 2010 11:00 AM").same_clock?(Time.parse("Dec 26, 2010 11:00 AM")) #=> true
    #   Time.parse("Dec 25, 2010 11:00 AM").same_clock?(Time.parse("Dec 26, 2010 08:00 AM")) #=> false
    def same_clock?(other_time)
      compare_clock(other_time) == 0
    end
  end
end

class Time #:nodoc: all
  include BusinessHoursModules::TimeExtensions
end