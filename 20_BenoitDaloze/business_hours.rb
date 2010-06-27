require "time"
Dir[File.expand_path("../*.rb", __FILE__)].each { |f| require f unless (f == __FILE__  or f =~ /.*_spec.rb$/)} # added a bit for unit test by ashbb

class BusinessHours
  attr_reader :base_rule, :rules
  NO_DAY = TimeRange.new(0..0)
  ALL_DAY = TimeRange.new(0..24)

  MIN = 60
  HOUR = 60 * MIN
  DAY = 24 * HOUR

  def initialize(opening, closing, &block)
    @rules = []
    @base_rule = Rule.new(opening, closing)
    instance_exec(&block) if block
  end

  def update(time, opening, closing)
    @rules << SpecialDay.new(time, opening, closing)
  end

  def closed(*days)
    days.each { |day|
      @rules << ClosingDay.new(day)
    }
  end

  def calculate_deadline(duration, start_time)
    start_time, duration = Time.parse(start_time), Rational(duration, HOUR)

    open, close = work_time(start_time).to_a
    today_work = close - [BusinessHours.parse_hour(start_time), open].max
    until today_work >= duration
      duration -= today_work

      open, close = work_time(start_time += DAY).to_a
      start_time = start_time.beginning_of_day + open*HOUR
      today_work = close - open
    end
    start_time + duration*HOUR
  end

  def work_time(day)
    work_time = @rules.map { |rule| rule.time_range(day) }.reduce(:&)
    work_time = @base_rule.time_range(day) if work_time.nil? or work_time == ALL_DAY
    work_time
  end

  def self.parse_day(day)
    case day
    when Symbol
      WeekDay.new(day)
    when String
      Time.parse(day)
    end
  end

  def self.parse_hour(hour) #=> Rational: (0-23h)+min/60
    case hour
    when Numeric
      hour
    when Time
      hour.hour + Rational(hour.min, MIN)
    when /\A(\d{1,2}):(\d{2}) (AM|PM)\z/
      $1.to_i+($3 == "PM" ? 12 : 0) + Rational($2.to_i, MIN)
    end
  end
end
