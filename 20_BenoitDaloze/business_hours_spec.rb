require "business_hours"

describe BusinessHours do
  let(:hours) {
    BusinessHours.new("9:00 AM", "3:00 PM") {
      update :fri, "10:00 AM", "5:00 PM"
      update "Fri Dec 24, 2010", "8:00 AM", "1:00 PM"
      closed :sun, :wed, "Dec 25, 2010"
    }
  }

  it "work_time" do
    hours.work_time(Time.parse("Mon Jun  7, 2010")).should == (9..3+12)

    hours.work_time(Time.parse("Fri Jun 11, 2010")).should == (10..5+12)

    hours.work_time(Time.parse("Fri Dec 24, 2010")).should == (8..1+12)

    hours.work_time(Time.parse("Sat Dec 25, 2010")).should == (0..0)
    hours.work_time(Time.parse("Wed Jun  9, 2010")).should == (0..0)
    hours.work_time(Time.parse("Sun Jun 13, 2010")).should == (0..0)
  end

  it "init test" do
    hours = BusinessHours.new("8:00 AM", "5:20 PM")
    hours.base_rule.opening.should == 8
    hours.base_rule.closing.should == 17+Rational(20,60)
    hours.calculate_deadline(   5*60, "Dec 21, 2009 3:00 PM").should == Time.parse("Mon Dec 21 15:05:00 2009")
  end

  it "basic test" do
    hours.calculate_deadline(2*60*60, "Jun  7, 2010 9:10 AM").should == Time.parse("Mon Jun 07 11:10:00 2010")
  end

  it "closed test" do
    hours.calculate_deadline(  15*60, "Jun  8, 2010 2:48 PM").should == Time.parse("Thu Jun 10 09:03:00 2010")
  end

  it "long test" do
    hours.calculate_deadline(7*60*60, "Dec 24, 2010 6:45 AM").should == Time.parse("Mon Dec 27 11:00:00 2010")
  end
end

