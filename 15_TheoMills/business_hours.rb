require 'date'
require 'time'

# Submission for RPCFN: Business Hours (#10)
# Theo Mills - June 2010
#
# BusinessHours creates a calendar of daily operating schedules for 
# days-of-the-week and specific dates.  
# 
# Opening and closing times are stored as an array of strings, 
# e.g. ["8:00 AM", "5:00 PM"], inside the calendar hashmap whose keys
# are either symbols (e.g. :wed, :thu, :fri) or date objects. Days 
# that are closed store their opening and closing times as an empty array.
#
# When retrieving a schedule for a specific date, a BusinessHours object
# first searches the calendar map for the corresponding date object. If 
# a matching date object is not found, then a search is made for the supplied 
# date's day-of-the-week symbol.

class BusinessHours
  
  DAYS = Date::ABBR_DAYNAMES.collect { |d| d.downcase.to_sym }
  
  attr_writer :calendar
  
  # Creates a calendar with a schedule for each day of the week
  # based on the supplied opening and closing times.
  def initialize(opens_at, closes_at)
    DAYS.each { |day| update(day, opens_at, closes_at) }
  end
  
  # Contains the opening and closing schedule for each day of the
  # week as well a specific dates. Closed schedules are represented
  # by an empty array of opening and closing times.
  def calendar
    @calendar ||= Hash.new
  end
  
  # Updates the calendar with opening and closing times for the
  # supplied day-of-week symbol or date string.
  def update(day, opens_at, closes_at)
    calendar[calendar_key(day)] = [opens_at, closes_at]
  end 

  # Updates a schedule as closed for the each of the supplied 
  # day-of-week symbols or date strings. Elements in the calendar 
  # with an empty Array for opening and closing times are considered closed.
  def closed(*days)
    days.each { |day| calendar[calendar_key(day)] = Array.new }
  end
  
  # Determines the resulting business time given a time interval (in seconds) 
  # along with a starting time (as a string). Returns an instance of Time.
  def calculate_deadline(seconds, time)                  
    time =  start_time(Time.parse(time))
    date = time_to_date(time)
    
    # Initialize tally of business time passed (in seconds) 
    tally = closing_time(date) - time
    
    # Move forward in business time until we surpass the supplied
    # time interval (in seconds)
    while seconds > tally
      date = next_business_day(date)
      tally += closing_time(date) - opening_time(date)      
    end
    
    closing_time(date) - (tally - seconds)
  end
    
  private
  
  # Determine which time to start tallying seconds with based
  # on position of the supplied starting time.
  def start_time(time)
    date = time_to_date(time)
    case
    when time < opening_time(date) # Before start of day
      opening_time(date)
    when closed?(date) || time >= closing_time(date) # After hours
      opening_time(next_business_day(date))
    else
      time # Within range of opening and closing times
    end
  end
  
  # Returns opening time for supplied date object or nil if closed for
  # that date.
  def opening_time(date)
    closed?(date) ? nil : schedule(date)[0]
  end
  
  # Returns closing time for supplied date object or nil if closed for
  # that date.
  def closing_time(date)
    closed?(date) ? nil : schedule(date)[1]
  end
  
  # Returns the opening and closing times for the specified date as an array 
  # of Time objects. In this array opening time is position 0, closing time 
  # is position 1. An empty array is returned if closed for the supplied date.
  def schedule(date)
    # Use the day of week if no schedule exists for the explicit date.
    key = calendar.has_key?(date) ? date : DAYS[date.wday].to_sym
    calendar[key].empty? ? [] : [date_to_time(date, calendar[key][0]), date_to_time(date, calendar[key][1])]
  end
  
  # Returns the next business day (as a Date object) in relation to 
  # the supplied date.
  def next_business_day(date)
    date = date.next
    date = date.next while closed?(date)
    date
  end  
  
  # True if closed for supplied date
  def closed?(date)
    schedule(date).empty?
  end
  
  # Convenience method to convert times to dates
  def time_to_date(time)
    Date.parse(time.strftime('%b %d, %Y'))
  end
  
  # Convenience method to convert dates to a specific time
  def date_to_time(date, time_of_day=nil)
    Time.parse(date.strftime("%b %d, %Y #{time_of_day}"))
  end
  
  # Determines the correct key for storing schedules in the
  # calendar hash.
  def calendar_key(obj)
    obj.is_a?(String) ? Date.parse(obj) : obj
  end

end

=begin
require 'test/unit'

class TestBusinessHours < Test::Unit::TestCase
  
  def setup
    @open, @close = "8:00 AM", "5:00 PM"    
    @hours = BusinessHours.new(@open, @close)
  end
  
  def test_init
    hours = BusinessHours.new(@open, @close)
    assert_equal [@open, @close], hours.calendar[:mon]
  end

  def test_day_of_week_update
    day, open, close = :sun, "10:00 AM", "6:00 PM"    
    @hours.update(day, open, close)
    assert_equal [open, close], @hours.calendar[day] 
  end
  
  def test_closed
    @hours.closed(:wed, :thu, "Dec 24, 2010")
    assert_equal Array.new, @hours.calendar[:wed]
    assert_equal Array.new, @hours.calendar[Date.parse("Dec 24, 2010")]
    assert_not_equal Array.new, @hours.calendar[:fri]
  end
  
  def test_date_update
    day, open, close = "Dec 24, 2010", "10:00 AM", "6:00 PM"    
    @hours.update(day, open, close)
    assert_equal [open, close], @hours.calendar[Date.parse(day)] 
  end
  
  def test_calculate_deadline        
    hours = BusinessHours.new("9:00 AM", "3:00 PM")
    hours.update :fri, "10:00 AM", "5:00 PM"
    hours.update "Dec 24, 2010", "8:00 AM", "1:00 PM"
    hours.closed :sun, :wed, "Dec 25, 2010"
    assert_equal Time.parse("Jun 10, 2010 09:03 AM"), hours.calculate_deadline(15*60, "Jun 8, 2010 2:48 PM")
    assert_equal Time.parse("Jun 07, 2010 11:10 AM"), hours.calculate_deadline(2*60*60, "Jun 7, 2010 9:10 AM")
    assert_equal Time.parse("Dec 24, 2010 08:15 AM"), hours.calculate_deadline(15*60, "Dec 24, 2010 6:45 AM")
    assert_equal Time.parse("Dec 27, 2010 11:00 AM"), hours.calculate_deadline(7*60*60, "Dec 24, 2010 6:45 AM")
  end
  
end
=end