require "time"
class BusinessHours
  @@schedule, DAYS = {}, [:sun, :mon, :tue, :wed, :thur, :fri, :sat]

  # Setup default schedule hours
  def initialize(open, close)
    DAYS.each{|day| update(day, open, close)}
  end

  def closed(*dates)
    dates.each{|date| update(date, nil, nil)}
  end

  def closed?(date)
    ((date.is_a? Hash) ? date : schedule(date)) == hours(nil, nil)
  end

  def update(date, open, close)
    schedule(date, hours(open, close))
  end

  def calculate_deadline(remaining, start_date)
    each(start_date) do |date, hours|
      next if closed?(hours)
      return date += remaining if((date + remaining) <= hours[:close])
      remaining -= (hours[:close] - date) if((date) <= hours[:close])
    end
  end

  # Iterate Scheduled Business Hours
  def each(current=Time.now, max=31)
    current = parse(current)
    stop_time = current + (max*24*60*60)
    while(current < stop_time)
      current_hours = day_hours(current)
      current = current_hours[:open] if(!closed?(current_hours) && current < current_hours[:open])# force to starting time
      yield [current, current_hours]
      current = parse("0:00 AM", current + 24*60*60)# prepare for next day
    end
  end
  
  private
  # Setter and Getter for Business Schedule; stores business hours for both defaults and exceptions.
  # Example:
  #   schedule(:sun)                            => Get Sunday's default hours
  #   schedule("7/4/2010")                      => Get July 4th's hours
  #   schedule(:sun, hours("8:00", "5:00 PM")}  => Set Sunday's default hours
  def schedule(date, val=nil)
    key = (date.is_a? Symbol) ? date : parse(date).strftime("%x")
    if val
      @@schedule[key] = val
    else
      @@schedule[key] || @@schedule[DAYS[parse(date).wday]]
    end
  end

  def hours(open, close)
    {:open => open, :close => close}
  end

  def day_hours(current)
    schedule(current).inject({}){ |hash,(k,v)| hash.merge( k => parse(v, current))}
  end

  # Returns Time Object
  def parse(*args)
    (args[0].is_a? String) ? Time.parse(*args) : args[0]
  end
end