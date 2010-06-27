class TimeRange < Range
  PRIORITIES = {
    :low => -1,
    :normal => 0,
    :high => 1
  }

  attr_reader :priority
  def initialize(range, priority = PRIORITIES[:normal])
    super(range.first, range.last)
    @priority = case priority
    when WeekDay
      PRIORITIES[:normal]
    when Time
      PRIORITIES[:high]
    else
      priority
    end
  end

  def == range
    first == range.first and last == range.last
  end

  def & range
    if [first, last, range.first, range.last].all? { |e| Numeric === e }
      if @priority != range.priority
        @priority > range.priority ? self : range
      else
        f, l = [first,range.first].max, [last,range.last].min
        TimeRange.new( f <= l ? (f..l) : (0..0), @priority )
      end
    end
  end

  def to_a
    [first, last]
  end
end
