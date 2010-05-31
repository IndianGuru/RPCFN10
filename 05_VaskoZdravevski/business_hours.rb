require 'set'
require 'time'

class Time
  def next_day
    Time.local(self.year, self.month, self.day + 1)
  end 

  def compare(start, finish)
    start = Time.mktime(self.year, self.month, self.day, start.hour, start.min)
    finish = Time.mktime(self.year, self.month, self.day, finish.hour, finish.min)
    return -1 if (self < start)
    return 0 if (self >= start) and (self <= finish)
    return 1 if (self > finish)
  end 
end

class BusinessHours
  attr_reader :open_days, :closed_days
  private :open_days, :closed_days

  def initialize(opening, closing)
    @open_days = { :default => {:open => Time.parse(opening), :close => Time.parse(closing)} }
    @closed_days = Set.new
  end 

  def update(day, opening, closing)
    open_days[day] = {:open => Time.parse(opening), :close => Time.parse(closing)}
  end 

  def closed(*days)
    closed_days.merge(days)
  end 

  def calculate_deadline(time_seconds, start_time)
    time = Time.parse(start_time)

    until time_seconds.zero? do
      time = time.next_day while day_off?(time)
      hours = get_hours(time)

      case time.compare(hours[:open], hours[:close])
      when -1
        time = Time.mktime(time.year, time.month, time.day, hours[:open].hour, hours[:open].min)
      when 1
        time = time.next_day
      when 0
        end_of_day = Time.mktime(time.year, time.month, time.day, hours[:close].hour, hours[:close].min)
        workable_time = (end_of_day - time)
        if (workable_time > time_seconds)
          time += time_seconds
          time_seconds = 0
        else
          time = time.next_day
          time_seconds -= workable_time
        end
      end
    end
    time
  end

  private
  def get_hours(time)
    return nil if day_off?(time)
    hours = open_days[:default]

    day_s = time.strftime('%b %d, %Y')
    day_sym = time.strftime('%a').downcase.to_sym
    hours = open_days[day_sym] if open_days[day_sym]
    hours = open_days[day_s] if open_days[day_s]
    hours
  end

  def day_off?(time)
    day_s = time.strftime('%b %d, %Y')
    day_sym = time.strftime('%a').downcase.to_sym
    closed_days.include?(day_sym) or closed_days.include?(day_s)
  end
end