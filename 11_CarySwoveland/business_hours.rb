#!/usr/bin/ruby

# Cary Swoveland
# Ruby 1.8.7.

# For this exercise, I didn't bother checking the validity of arguments in calls
# to BusinessHours' public methods, e.g., :moo for a day-of-week would cause an error.

require 'date' # Needed for DateTime::parse in String#to_time below
require 'time' # Needed for Time::RFC2822_DAY_NAME in BusinessHours#wday_symbol_to_wday

# Add two helper methods to Time class.
class Time
  def copy_date other_time
    # Called from BusinessHours#hours_today.
    # Returns value of self with other_time's date, but leaves self's time-of-day unchanged.
    Time.local other_time.year, other_time.mon, other_time.day, self.hour, self.min, self.sec
  end
  
  def zero_time_of_day
    # Called from BusinessHours#store_open_today? and BusinessHours#hours_today.
    # Returns value of self with time-of-day zeroed, but date unchanged.
    Time.local self.year, self.mon, self.day
  end
end

# Add helper method to String class.
class String
  # Called from BusinessHours#initialize, BusinessHours#update,
  # BusinessHours#closed and BusinessHours#calculate_deadline.
  def to_time
    dt = DateTime.parse self # Note: Time#parse is not available in Ruby 1.8.7.
    Time.local dt.year, dt.month, dt.day, dt.hour, dt.min, dt.sec # Fracs of a sec not used.
  end
end
    
class BusinessHours
  SECS_PER_DAY = 86400 # = 24*60*60
  
  def initialize normal_open_time_str, normal_close_time_str
    @hours_by_wday = Array.new(7, [normal_open_time_str.to_time, normal_close_time_str.to_time])
    @closed_by_wday = Array.new(7, false) # Default is store open every day of week.
    @hours_by_date = {} # date => [open_time, close_time], all three Time objects
    @closed_by_date = {} # date => true, date Time object
  end

  def update d, open_time_str, close_time_str
    # Change business hours by day-of-week or for selected dates.
    hours = [open_time_str.to_time, close_time_str.to_time]
    if d.is_a? Symbol
      @hours_by_wday[wday_symbol_to_wday d] = hours # e.g., d = :Fri, :FRI or :fRI.
    else
      @hours_by_date[d.to_time] = hours # e.g., d = "Dec 25, 2010".
      # Note: d.to_time.hour = d.to_time.min = d.to_time.sec = 0
    end
  end
  
  def closed *day_list 
    # Change days closed by day-of-week or for selected dates.
    day_list.each { |d|
      if d.is_a? Symbol 
        @closed_by_wday[wday_symbol_to_wday d] = true # e.g., d = :Fri, :FRI or :fRI.
      else
        @closed_by_date[d.to_time] = true # e.g., d = "Dec 25, 2010".
        # Note: d.to_time.hour = d.to_time.min = d.to_time.sec = 0
      end
    }
  end  

  def calculate_deadline secs_remaining, start_time_str
    # Return a Time object whose value equals the deadline for the comletion of the work.
    curr_time = start_time_str.to_time
    if (store_open_today? curr_time) and (curr_time < (closing_time_today curr_time))
      # If curr_time is before opening time, skip to the opening time.
      open_time = opening_time_today curr_time
      curr_time = open_time if curr_time < open_time
    else # Store is closed, so skip to the next opening date and time.   
      curr_time = next_opening_time curr_time
    end  
    deadline secs_remaining, curr_time
  end
  
  private

  def deadline secs_remaining, curr_time
    # Called from calculate_deadline and from itself. 
    # Note: the store is open at curr_time whenever this method is called.
    time_until_closing = (closing_time_today curr_time) - curr_time
    # We are finished if the deadline occurs before closing today.
    return curr_time + secs_remaining if secs_remaining <= time_until_closing
    # Else reduce secs_remaining and skip to the next store opening time.
    deadline secs_remaining - time_until_closing, (next_opening_time curr_time) 
  end

  def next_opening_time curr_time
    # Called from calculate_deadline and deadline. 
    curr_time += SECS_PER_DAY # Must skip to the next day before entering loop.
    curr_time += SECS_PER_DAY until store_open_today? curr_time 
    opening_time_today curr_time
  end

  def store_open_today? curr_time
    # Called from next_opening_time.
    # In case of conflicting data regarding days open, the first priority is assumed
    # to be closed(date), the second priority, update(date, open_time, close_time)
    # and and the third priority, closed(day-of-week).  For example, if we have
    # closed("July 22, 2010") and update ("July 22, 2010" "11:00 AM", "4:30 PM"),
    # we assume the store is closed on that date, but if we had
    # update("July 25, 2010" "11:00 AM", "4:30 PM") and closed(:sun) (July 25, 2010
    # falls on a Sunday), we would assume the store is open on that date.
       
    # We must zero time-of-day in curr_time in order to use curr_time
    # as the key in the hashes @closed_by_date and @hours_by_date.
    return false if @closed_by_date[curr_time.zero_time_of_day]
    return true if @hours_by_date[curr_time.zero_time_of_day]
    return !@closed_by_wday[curr_time.wday]
  end

  def opening_time_today curr_time
    # Called from next_opening_time. 
    (hours_today curr_time)[0]
  end  
  
  def closing_time_today curr_time
    # Called from deadline. 
    (hours_today curr_time)[1]
  end  

  def hours_today curr_time
    # Called from opening_time_today and closing_time_today.
    # hours = [open time, close time], open_time and close_time being Time objects.
    # hours by date is given priority over hours by day of week.
  
    # We must zero time-of-day in curr_time in order to use curr_time
    # as the key in the hash @hours_by_date.  
    hours = @hours_by_date[curr_time.zero_time_of_day] # = nil if no value for key.
    hours = @hours_by_wday[curr_time.wday] if !hours
    # Set hours' dates to curr_time's date (with hours' time-of-day unchanged)
    # so we can easily compare today's opening and closing times with curr_time.
    [(hours[0].copy_date curr_time), (hours[1].copy_date curr_time)] 
  end
  
  def wday_symbol_to_wday sym
    # Called from update and closed.
    # sym = :Fri, :FRI and :fRI all return wday = 5.
    Time::RFC2822_DAY_NAME.index(sym.to_s.capitalize)
  end
end

#----------------------------------------------------------------------

# Test code and test cases shown below.  As indicated, this was run from a separate file.
=begin

#!/usr/bin/ruby

# Note: code used for testing is commented out at end of this file.

#require 'test/unit' ** not used
require 'dry_cleaner_challenge'
# Note: require 'date' is in dry_cleaner_challenge.rb

class BusinessHoursTest # ** < Test::Unit::TestCase not used
  def initialize
    c = 0

    puts "Case #{c+=1}" 
    b = BusinessHours.new "9:00 AM", "3:00 PM"
    b.update :fri, "10:00 AM", "5:00 PM"
    b.update "Dec 24, 2010", "8:00 AM", "1:00 PM"
    b.closed :sun, :wed, "Dec 25, 2010"
    # June 7 is a Mon., Dec. 24 is a Fri.
    compute_deadline b, 2, 0, 0, "Jun 7, 2010 9:10 AM", "Jun 7, 2010 11:10 AM"
    compute_deadline b, 0, 15, 0, "Jun 8, 2010 2:48 PM", "Jun 10, 2010 9:03 AM"
    compute_deadline b, 7, 0, 0, "Dec 24, 2010 6:45 AM", "Dec 27, 2010 11:00 AM"
    puts ""
    
    puts "Case #{c+=1}"
    b = BusinessHours.new "8:00 AM", "6:00 PM"
    b.update :fri, "1:00 PM", "5:00 PM"
    b.update :wed, "9:00 AM", "8:00 PM"
    b.update "Jul 12, 2010", "11:00 AM", "5:00 PM"
    b.update "July 13, 2010", "1:00 PM", "5:00 PM"
    b.closed :sat, :SUn, :mon, "Jul 13, 2010"
    # Jul 9 is a Fri., Jul 12 a Mon.
    compute_deadline b, 0, 1, 0, "Jul 9, 2010 5:00 PM", "Jul 12, 11:01:00 AM"
    compute_deadline b, 4, 2, 3, "Jul 9, 2010 7:00 AM", "Jul 12, 11:02:03 AM"
    compute_deadline b, 8, 15, 1, "Jul 9, 2010 3:30 PM", "Jul 14, 9:45:01 AM"
    puts ""
  end

  private
    
  def compute_deadline b, hh, mm, ss, start_date_str, expected_deadline_str
    secs_available = 60*(60*hh + mm) + ss
    deadline = b.calculate_deadline hh_mm_ss_to_secs(hh,mm,ss), start_date_str
    puts "Test for time available = #{hh}:#{mm}:#{ss}, start_time #{start_date_str}, wday #{start_date_str.to_time.wday},"
    print "  expected deadline = #{expected_deadline_str}"
    if deadline == expected_deadline_str.to_time
    puts ": Success!"
    else
      puts "  Error!"
      puts "  Calculated deadline = #{deadline.strftime "%b %d, %Y %I:%M:%S %p"}"
    end
#   assert_equal(deadline, expected_deadline_str.to_time) ** not used.
  end

  def hh_mm_ss_to_secs hh, mm, ss
    60*(60*hh + mm) + ss
  end
end

t = BusinessHoursTest.new

=end
