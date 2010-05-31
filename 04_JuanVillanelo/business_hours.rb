require 'time'
class BusinessHours
  def initialize(o,c)
    @times = {:wdays => Hash.new([o,c]),:dates => {}}
    @closed = {:wdays => [], :dates => []}
  end
  def update(date,o,c)
    if date.is_a?(Symbol)
      @times[:wdays][date] = [o,c]
    else
      @times[:dates][Time.parse(date)] = [o,c]
    end
  end
  def closed(*dates)
    dates.each do |date|
      if date.is_a?(Symbol)
        @closed[:wdays] << date
      else
        @closed[:dates] << Time.parse(date)
      end
    end
  end
  def open?(date)
    return false if @closed[:wdays].include?(date.strftime("%a").downcase.to_sym)
    return false if @closed[:dates].include?(Time.parse("0:0:0",date))
    true
  end
  def get_times(date)
    base = Time.parse("0:0:0",date)
      if @times[:dates].include?(base)
        @times[:dates][base].map{|t| Time.parse(t,base)}
      else
        @times[:wdays][date.strftime("%a").downcase.to_sym].map{|t| Time.parse(t,base)}
      end
  end
  def calculate_deadline(time,date)
    t = Time.parse(date)
    begin
      if open?(t)
        o,c = get_times(t) # time instances for opening and closing
        start = (t == Time.parse(date) && t > o) ? t : o 
        if (c - start) > time
          #puts start + time ; break
          return start + time    # edited by ashbb for unit test
        else 
          time -= c - start
        end
      end
    end while t += 24*60*60 
  end
end