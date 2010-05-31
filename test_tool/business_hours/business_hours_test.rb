require "test/unit"
#require File.dirname(__FILE__) + '/business_hours'

class BusinessHoursTest < Test::Unit::TestCase
  def setup
    @hours = BusinessHours.new("8:00 AM", "5:00 PM")
  end
  
  def test_within_working_hours
    assert_equal Time.parse("Dec 21, 2009 3:05 PM"), @hours.calculate_deadline(5*60, "Dec 21, 2009 3:00 PM")
  end
  
  def test_start_at_opening_time
    assert_equal Time.parse("Dec 21, 2009 8:05 AM"), @hours.calculate_deadline(5*60, "Dec 21, 2009 7:27 AM")
  end
  
  def test_start_next_day_when_after_closing_time
    assert_equal Time.parse("Dec 21, 2009 8:05 AM"), @hours.calculate_deadline(5*60, "Dec 20, 2009 6:37 PM")
  end
  
  def test_carry_over_remaining_time_onto_next_day
    assert_equal Time.parse("Dec 22, 2009 8:02 AM"), @hours.calculate_deadline(5*60, "Dec 21, 2009 4:57 PM")
  end
  
  def test_skip_full_day
    assert_equal Time.parse("Dec 23, 2009 8:57 AM"), @hours.calculate_deadline(10*60*60, "Dec 21, 2009 4:57 PM")
  end
  
  def test_skip_current_day_before_opening
    assert_equal Time.parse("Dec 22, 2009 9:00 AM"), @hours.calculate_deadline(10*60*60, "Dec 21, 2009 7:57 AM")
  end
  
  def test_update_week_day_hours
    @hours.update :mon, "8:00 AM", "3:00 PM"
    @hours.update :tue, "9:00 AM", "5:00 PM"
    assert_equal Time.parse("Dec 22, 2009 9:02 AM"), @hours.calculate_deadline(5*60, "Dec 21, 2009 2:57 PM")
  end
  
  def test_skip_closed_days
    @hours.closed :sat, :sun
    assert_equal Time.parse("Dec 21, 2009 8:02 AM"), @hours.calculate_deadline(5*60, "Dec 18, 2009 4:57 PM")
  end
  
  def test_change_hours_for_specific_dates
    @hours.update "Dec 24, 2009", "8:00 AM", "3:00 PM"
    @hours.closed :sat, :sun, "Dec 25, 2009"
    assert_equal Time.parse("Dec 28, 2009 8:02 AM"), @hours.calculate_deadline(5*60, "Dec 24, 2009 2:57 PM")
    assert_equal Time.parse("Dec 17, 2009 3:02 PM"), @hours.calculate_deadline(5*60, "Dec 17, 2009 2:57 PM")
  end
end
