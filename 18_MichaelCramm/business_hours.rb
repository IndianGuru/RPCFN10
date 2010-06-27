require 'time' 

class Day
  attr_accessor :open, :closed

  def initialize(open = nil, closed = nil)
    self.set_hours(open, closed)
  end

  def closed?
    self.open == '0:00 AM' && self.closed == '0:00 AM'
  end
  
  def set_hours(open, closed)
    self.open, self.closed = open, closed
  end
end

class Time  
  def parse_time(time)
    Time.parse(self.strftime('%D') << " " << time)
  end
end

# the above code are added from day.rb for unit test by ashbb

class BusinessHours
  attr_accessor :days
  
  def initialize(open, closed)
    @days = Hash.new
    %w(sun mon tue wed thu fri sat).each {|day| @days[day.intern] = Day.new(open, closed)}  # => Set hours for each day of the week
  end
  
  def update(day, open, closed)
    day = Time.parse(day).strftime('%D') if day.kind_of? String # => '%D' used to create a rule for this date
    
    if day.kind_of?(String) || day.kind_of?(Symbol)   # => Only symbols/strings should be allowed
      @days[day] = Day.new if @days[day].nil?
      @days[day].set_hours(open, closed)  
    else
      puts "The first parameter needs to be a Symbol or a String. (Entered #{day} => #{day.class})"
    end 
  end
  
  def display   # => Simple display of current hours
    puts"[Day] => [Open] to [Closed]"
    
    @days.keys.each {|key| puts @days[key].closed? ? "#{key} => CLOSED" : "#{key} => #{@days[key].open} to #{@days[key].closed}"}
  end
  
  def closed(*args)
    args.each {|a| update(a, "0:00 AM", "0:00 AM") }  # => 0:00 to 0:00 will represent closed
  end
  
  def calculate_deadline(time_required, start_string)
    start_time = current_time = Time.parse(start_string)
    
    while(time_required > 0)
      # => '%D' used to check if a rule has been created specific to this date
      day = @days[current_time.strftime('%D')] ? @days[current_time.strftime('%D')] : @days[current_time.strftime('%a').downcase.intern]

      # => Creates time objs for the current date's opening/closing
      opening_time, closing_time = current_time.parse_time(day.open), closing_time = current_time.parse_time(day.closed)
        
      # => If before opening time, set current_time to opening
      current_time = Time.at(opening_time) if opening_time > current_time  

      if !day.closed? && current_time < closing_time
        # => Check if we're going past closing. If not, return. Otherwise, calculate!
        current_time + time_required < closing_time ? (return current_time + time_required) : (time_required -= (closing_time.to_i - current_time.to_i))
      end   
      
      current_time = Time.parse((current_time + 24*60*60).strftime('%D'))  # => Go To tomorrow
      
      return "Couldn't finish safely" if (current_time - start_time) >= (24*60*60)*30 # => Saftey! Stop if we pass 30 days.
    end
  end
  
end