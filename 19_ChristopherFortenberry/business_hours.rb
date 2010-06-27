#####################################
# BusinessHours project for RPCFN10 #
# Christopher Fortenberry           #
#                                   #
# http://twitter.com/cpfortenberry  #
# http://gitub.com/CPFB             #
#####################################

require 'time'
require 'date'

class BusinessHours
  
  DAY_HASH = {  :sun  => 0,
                :mon  => 1,
                :tue  => 2,
                :wed  => 3,
                :thur => 4,
                :fri  => 5,
                :sat  => 6
             } 
             
             
  # PUBLIC METHODS


  def initialize(start_time, end_time)
    self.start_time_must_be_before_end_time(start_time, end_time)
    @start_time = start_time
    @end_time = end_time
    @closed_days_of_week = []
    @closed_dates = []
    @different_day_of_week_hours = []
    @different_date_hours = []
  end
  
  # stores updated day/times in an array
  # days and specific dates stored in different arrays
  def update(day, start_time, end_time)
    # error checking for day, start_time, and end_time formats
    self.start_time_must_be_before_end_time(start_time, end_time)
    # if it's a symbol, check to make sure the symbol is valid and then add the day
    if day.class == Symbol
      self.check_for_hash_error(day)
      self.add_day_to_array(DAY_HASH[day], start_time, end_time, @different_day_of_week_hours)
    # if it's not a symbol, add the day
    else # specific day
      self.add_day_to_array(day, start_time, end_time, @different_date_hours)
    end
  end
  
  # adds close dates (and makes sure there's no duplicates)
  def closed(*days)
    for day in days
      if day.class == Symbol
        self.check_for_hash_error(day)
        self.add_close_date(DAY_HASH[day], @closed_days_of_week)
      else
        self.add_close_date(day, @closed_dates)
      end
    end
  end
  
  def calculate_deadline(interval, drop_time)
    # error checking for time format
    # initialize deadline (return + flag), remaining_interval (counts down interval), working_time (counts up to deadline)
    deadline = nil
    remaining_interval = interval
    working_time = Time.parse(drop_time)
    # repeat these steps until you set a deadline (each iteration through the loop should equal one day)
    while !deadline do
      # gets the operating hours for the current day
      start_time, end_time = self.get_daily_operating_hours(working_time)
      # if the store is open
      if (start_time && end_time)
        # if the working time is earlier than the start time, set the working time to the start time
        working_time = start_time if working_time < start_time
        # if there is less time in the operating day than the remaining interval, 
        #   decrement the remaining interval, otherwise set the deadline
        if (end_time - working_time) <= remaining_interval
          remaining_interval -= (end_time - working_time)
        else 
          deadline = working_time + remaining_interval
        end
      end
      # advance working time to the next day
      working_date = Date.new(working_time.year, working_time.month, working_time.day)
      working_date = working_date.next
      working_time = Time.local(working_date.year, working_date.month, working_date.day)
    end # while
    
    return deadline
  end
  
  
  # HELPER METHODS
  
    
  def add_day_to_array(day, start_time, end_time, array)
    old_entry = array.find { |entry| entry[0] == day }
    array.delete_if { |entry| entry == old_entry } if old_entry
    array << [ day, start_time, end_time ]    
  end
  
  def add_close_date(day, array)
    array << day if !(array.find { |entry| entry == day })
  end
  
  # day is a Time class
  def get_daily_operating_hours(day)
    day_of_week = day.wday
    # find day in closed_dates
    if @closed_dates.find { |entry| Time.parse(entry) == day }
      start_time = nil
      end_time = nil
    # find day in different_date_hours
    elsif @different_date_hours.find { |entry| self.same_day?(Time.parse(entry[0]), day) }
      hours_array = @different_date_hours.find { |entry| self.same_day?(Time.parse(entry[0]), day) }
      start_time = hours_array[1]
      end_time = hours_array[2]
    # find day in closed_days_of_week
    elsif @closed_days_of_week.find { |entry| entry == day_of_week }
      start_time = nil
      end_time = nil
    # find day in different_day_of_week_hours
    elsif @different_day_of_week_hours.find { |entry| entry[0] == day_of_week }
      hours_array = @different_day_of_week_hours.find { |entry| entry[0] == day_of_week }
      start_time = hours_array[1]
      end_time = hours_array[2]
    # standard business hours
    else
      start_time = @start_time
      end_time = @end_time
    end
    
    if start_time
      start_time = Time.parse(start_time)
      final_start_time = Time.local(day.year, day.month, day.day, start_time.hour, start_time.min, start_time.sec)
    end
    if end_time
      end_time = Time.parse(end_time)
      final_end_time = Time.local(day.year, day.month, day.day, end_time.hour, end_time.min, end_time.sec)
    end
    return final_start_time, final_end_time
  end
  
  # both are time instances
  def same_day?(time_1, time_2)
    day_1 = Date.new(time_1.year, time_1.month, time_1.day)
    day_2 = Date.new(time_2.year, time_2.month, time_2.day)
    return day_1 == day_2
  end
  
  
  # ERROR CHECKING
  
  
  def check_for_hash_error(day)
    raise ArgumentError, "Not a valid day of the week" if !(DAY_HASH.find { |key, value| key == day })
  end
    
  def start_time_must_be_before_end_time(start_time, end_time)
    raise ArgumentError, "start_time must be before end_time" if (Time.parse(start_time) > Time.parse(end_time))
  end
  
  
end