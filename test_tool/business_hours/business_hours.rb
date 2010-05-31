require "date"
require "time"

class BusinessHours
  def initialize(opening, closing)
    @schedule = { :default => [opening, closing] }
  end
  
  def update(day, opening, closing)
    key = day.kind_of?(Symbol) ? Date.parse(day.to_s).wday : Date.parse(day.to_s)
    @schedule[key] = [opening, closing]
  end
  
  def closed(*days)
    days.each { |day| update(day, "0:00", "0:00") }
  end
  
  def calculate_deadline(interval, start_time)
    Deadline.new(@schedule, interval, Time.parse(start_time)).calculate
  end
  
  class Deadline
    def initialize(*args)
      @schedule, @remaining, @current_time = *args
    end
    
    def calculate
      increment_day while after_today?
      @current_time + @remaining
    end
    
    private
    
    def after_today?
      if @current_time < opening_time
        @current_time = opening_time
      end
      @current_time + @remaining > closing_time
    end
    
    def increment_day
      if @current_time < closing_time
        @remaining -= closing_time - @current_time
      end
      @current_time = Time.parse((@current_time + 24*60*60).strftime("%Y-%m-%d"))
    end
    
    def opening_time
      Time.parse(@current_time.strftime("%Y-%m-%d ") + current_hours.first)
    end
    
    def closing_time
      Time.parse(@current_time.strftime("%Y-%m-%d ") + current_hours.last)
    end
    
    def current_hours
      @schedule[Date.new(@current_time.year, @current_time.month, @current_time.day)] || @schedule[@current_time.wday] || @schedule[:default]
    end
  end
end
