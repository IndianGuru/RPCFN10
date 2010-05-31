class BusinessHours

  require 'time'
  require 'date'

  def initialize(start_time, end_time)
    @specs = { :default => [start_time, end_time] }
  end

  def update(date_spec, start_time, end_time)
    date_spec = start_of_day(Time.parse(date_spec)) if String === date_spec
    @specs[date_spec] = [start_time, end_time]
    self
  end

  def closed(*date_specs)
    date_specs.each do |date_spec|
      date_spec = start_of_day(Time.parse(date_spec)) if String === date_spec
      @specs[date_spec] = :closed
    end
    self
  end

  def calculate_deadline(duration, start)
    time = Time.parse(start)

    loop do
      spec = find_spec(time)

      if spec == :closed
        time = next_day(time)
        next
      end

      s, e = *spec

      if time > e
        time = next_day(time)
        next
      end

      if time > s
        s = time
      end

      day_duration = e - s

      if day_duration > duration
        return s + duration
      else
        duration -= day_duration
        time = next_day(time)
      end

    end
  end

private

  def find_spec(time)
    spec = (@specs[start_of_day(time)] || @specs[int_to_day(time.wday)] || @specs[:default])
    if spec == :closed
      spec
    else
      [set_time(time, spec.first), set_time(time, spec.last)]
    end
  end

  def int_to_day(int)
    case int
    when 0 then :sun
    when 1 then :mon
    when 2 then :tue
    when 3 then :wed
    when 4 then :thu
    when 5 then :fri
    when 6 then :sat
    end
  end

  def start_of_day(time)
    time - (time.hour * 60 * 60) - (time.min * 60) - (time.sec)
  end

  def next_day(time)
    start_of_day(time) + (24 * 60 * 60)
  end

  def set_time(time, spec)
    delta = Time.parse(spec)
    start_of_day(time) + (delta.hour * 60 * 60) + (delta.min * 60) + (delta.sec)
  end

end

=begin
require 'test/unit'

class BusinessHoursTest < Test::Unit::TestCase
  def setup
    @hours = BusinessHours.new("9:00 AM", "3:00 PM")
    @hours.update :fri, "10:00 AM", "5:00 PM"
    @hours.update "Dec 24, 2010", "8:00 AM", "1:00 PM"
    @hours.closed :sun, :wed, "Dec 25, 2010"
  end

  def test_a
    a = @hours.calculate_deadline(2*60*60, "Jun 7, 2010 9:10 AM")
    b = Time.parse("Mon Jun 07 11:10:00 2010")
    assert_equal a, b
  end

  def test_b
    a = @hours.calculate_deadline(15*60, "Jun 8, 2010 2:48 PM")
    b = Time.parse("Thu Jun 10 09:03:00 2010")
    assert_equal a, b
  end

  def test_c
    a = @hours.calculate_deadline(7*60*60, "Dec 24, 2010 6:45 AM")
    b = Time.parse("Mon Dec 27 11:00:00 2010")
    assert_equal a, b
  end
end
=end