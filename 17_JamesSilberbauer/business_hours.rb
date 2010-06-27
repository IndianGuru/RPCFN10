# business_hours.rb
#
require 'time'

# Helpers on the Time class
class Time
  # Key to the DayRules - day abbreviation as a symbol.
  def key_by_day
    [:sun, :mon, :tue, :wed, :thu, :fri, :sat][self.wday]
  end

  # Key to the DayRules - date as YYYY-MM-DD.
  def key_by_date
    self.strftime('%Y-%m-%d')
  end

  # Start of the next day.
  def next_day_at_midnight
    Time.parse(self.strftime('%Y-%m-%d')) + (24*60*60)
  end

  # Change the time.
  def set_time_to(time)
    Time.local(self.year, self.month, self.day, time.hour, time.min)
  end
end

# The rules for a day: closed?, opening time and closing time.
class DayRule
  attr_accessor :opening_time, :closing_time, :is_closed

  def initialize(opening_time, closing_time, is_closed=false)
    @opening_time = Time.parse(opening_time)
    @closing_time = Time.parse(closing_time)
    @is_closed    = is_closed
  end

  # Number of seconds from the given time until closing time.
  def seconds_in_day_from(time)
    if @is_closed || time > time.set_time_to( @closing_time )
      0
    else
      time.set_time_to( @closing_time ) - start_time(time)
    end
  end

  # Bring a time forward to the opening time if it is earlier.
  def start_time(time)
    if time < time.set_time_to( @opening_time )
      time.set_time_to( @opening_time )
    else
      time
    end
  end
end

# Store the business hours rules and calculate the deadline.
class BusinessHours
  def initialize(opening_time, closing_time)
    @opening_time = opening_time
    @closing_time = closing_time
    @day_rules    = {}
    [:sun, :mon, :tue, :wed, :thu, :fri, :sat].each do |day|
      @day_rules[day] = DayRule.new(@opening_time, @closing_time)
    end
  end

  def update(day_or_date, opening_time, closing_time)
    date_key = make_date_key(day_or_date)
    if @day_rules[date_key]
      @day_rules[date_key].opening_time = Time.parse(opening_time)
      @day_rules[date_key].closing_time = Time.parse(closing_time)
    else
      @day_rules[date_key] = DayRule.new(opening_time, closing_time)
    end
  end

  def closed(*closed_days)
    closed_days.each do |closed_on|
      date_key = make_date_key(closed_on)
      if @day_rules[date_key]
        @day_rules[date_key].is_closed = true
      else
        @day_rules[date_key] = DayRule.new(@opening_time, @closing_time, true)
      end
    end
  end

  def calculate_deadline(seconds, from_time)
    @this_day = Time.parse(from_time)

    while seconds > 0 do
      if seconds < day_rule.seconds_in_day_from(@this_day)
        @this_day = day_rule.start_time(@this_day) + seconds
        seconds   = 0
      else
        seconds  -= day_rule.seconds_in_day_from(@this_day)
        @this_day = @this_day.next_day_at_midnight
      end
    end
    @this_day
  end

private
  # Find the matching day rule. First check using the specific date as those rules
  # have precedence over the day of the week rules.
  def day_rule
    @day_rules[@this_day.key_by_date] || @day_rules[@this_day.key_by_day]
  end

  # Make sure the keys to be used in seeking the day rules are consistent.
  # This ensures that <tt>hours.update "Dec 24, 2010", "8:00 AM", "1:00 PM"</tt>
  # and <tt>hours.update "2010-12-24", "8:00 AM", "1:00 PM"</tt> do the same thing.
  def make_date_key(day_or_date)
    if day_or_date.class == Symbol
      day_or_date
    else
      Time.parse(day_or_date).key_by_date
    end
  end
end

if $0 == __FILE__
  require 'test/unit'
  # Tests
  class BusinessHoursTest < Test::Unit::TestCase
    def setup
      @hours = BusinessHours.new("9:00 AM", "3:00 PM")
      @hours.update :fri, "10:00 AM", "5:00 PM"
      @hours.closed :sun, :wed, "Dec 25, 2010"
    end

    def test_basic
      assert_equal(Time.parse("Mon Jun 07 11:10:00 2010"), @hours.calculate_deadline(2*60*60, "Jun 7, 2010 9:10 AM"))
    end

    def test_late
      assert_equal(Time.parse("Thu Jun 10 09:03:00 2010"), @hours.calculate_deadline(15*60, "Jun 8, 2010 2:48 PM"))
    end

    def test_holiday
      @hours.update "Dec 24, 2010", "8:00 AM", "1:00 PM"
      assert_equal(Time.parse("Mon Dec 27 11:00:00 2010"), @hours.calculate_deadline(7*60*60, "Dec 24, 2010 6:45 AM"))
    end

    def test_holiday_alternate
      @hours.update "2010-12-24", "8:00 AM", "1:00 PM"
      assert_equal(Time.parse("Mon Dec 27 11:00:00 2010"), @hours.calculate_deadline(7*60*60, "Dec 24, 2010 6:45 AM"))
    end
  end
end
