class WeekDay
  def initialize(sym)
    @sym = sym
  end

  def same_day?(time)
    time.strftime("%a").downcase == @sym.to_s
  end
end
