require 'lib/business_hours.rb'

describe BusinessHours do

  subject { BusinessHours.new("9:00 AM", "3:00 PM") }

  it { should respond_to(:update) }

  it { should respond_to(:closed) }

  it { should respond_to(:calculate_deadline) }

  context "schedule without exceptions" do
    before { @hours = BusinessHours.new("9:00 AM", "3:00 PM") }

    it "should handle start time during open hours" do
      @hours.calculate_deadline(1*60*60, "Jun 7, 2010 9:10 AM").should == Time.parse("Jun 7, 2010 10:10 AM")
    end

    it "should handle start time before open hours" do
      @hours.calculate_deadline(2*60*60, "Jun 7, 2010 8:45 AM").should == Time.parse("Jun 7, 2010 11:00 AM")
    end

    it "should handle start time after open hours" do
      @hours.calculate_deadline(2*60*60, "Jun 7, 2010 10:45 PM").should == Time.parse("Jun 8, 2010 11:00 AM")
    end

    it "should finish job next day if not enough time left" do
      @hours.calculate_deadline(2*60*60, "Jun 7, 2010 2:45 PM").should == Time.parse("Jun 8, 2010 10:45 AM")
    end

    it "should process huge job for several days" do
      @hours.calculate_deadline(20*60*60, "Jun 7, 2010 10:45 AM").should == Time.parse("Jun 10, 2010 12:45 PM")
    end

    it "should flip the edge" do
      @hours.calculate_deadline(6*60*60, "Jun 7, 2010 9:00 AM").should == Time.parse("Jun 8, 2010 9:00 AM")
    end

    # this is also possible, but I prefer previous variant
    #
    # it "should NOT flip the edge" do
    #   @hours.calculate_deadline(6*60*60, "Jun 7, 2010 9:00 AM").should == Time.parse("Jun 7, 2010 3:00 PM")
    # end

    context "on dst changes" do

      it "should respect changing to dst" do
        @hours.calculate_deadline(8*60*60, "March 27, 2010 2:00 PM").should == Time.parse("March 29, 2010 10:00 AM")
      end

      it "should respect changing to dst" do
        @hours.calculate_deadline(2*60*60, "March 27, 2010 2:00 PM").should == Time.parse("March 28, 2010 10:00 AM")
      end

      it "should respect changing from dst" do
        @hours.calculate_deadline(8*60*60, "October 31, 2010 2:00 PM").should == Time.parse("November 2, 2010 10:00 AM")
      end

      it "should respect changing from dst" do
        @hours.calculate_deadline(2*60*60, "October 31, 2010 2:00 PM").should == Time.parse("November 1, 2010 10:00 AM")
      end

    end

  end

  context "schedule with closed weekdays" do
    before do
      @hours = BusinessHours.new("9:00 AM", "3:00 PM")
      @hours.closed :sun, :wed
    end

    it "should skip closed days" do
      @hours.calculate_deadline(2*60*60, "Jun 5, 2010 2:45 PM").should == Time.parse("Jun 7, 2010 10:45 AM")
    end

    it "should skip closed days even if work scheduled to closed day" do
      @hours.calculate_deadline(2*60*60, "Jun 6, 2010 11:45 AM").should == Time.parse("Jun 7, 2010 11:00 AM")
    end
  end

  context "schedule with closed specific days" do

    before do
      @hours = BusinessHours.new("9:00 AM", "3:00 PM")
      @hours.closed "Dec 25, 2010"
    end

    it "should skip closed days" do
      @hours.calculate_deadline(2*60*60, "Dec 24, 2010 2:45 PM").should == Time.parse("Dec 26, 2010 10:45 AM")
    end

    it "should skip closed days even if work scheduled to closed day" do
      @hours.calculate_deadline(2*60*60, "Dec 25, 2010 11:45 AM").should == Time.parse("Dec 26, 2010 11:00 AM")
    end

  end

  context "schedule with both closed weekdays and specific days" do

    before do
      @hours = BusinessHours.new("9:00 AM", "3:00 PM")
      @hours.closed :sun, :wed, "Dec 25, 2010"
    end

    it "should skip closed days" do
      @hours.calculate_deadline(2*60*60, "Dec 24, 2010 2:45 PM").should == Time.parse("Dec 27, 2010 10:45 AM")
    end
  end

  context "schedule with different open hours in weekdays" do
    before do
      @hours = BusinessHours.new("9:00 AM", "3:00 PM")
      @hours.update :fri, "10:00 AM", "5:00 PM"
    end

    it "should spend open hours" do
      @hours.calculate_deadline(14*60*60, "Jun 3, 2010 9:00 AM").should == Time.parse("Jun 5, 2010 10:00 AM")
    end

  end

  context "schedule with different open hours in specific days" do
    before do
      @hours = BusinessHours.new("9:00 AM", "3:00 PM")
      @hours.update "Dec 24, 2010", "8:00 AM", "1:00 PM"
    end

    it "should spend open hours" do
      @hours.calculate_deadline(12*60*60, "Dec 23, 2010 9:00 AM").should == Time.parse("Dec 25, 2010 10:00 AM")
    end

    it "should spend open hours if started at the day" do
      @hours.calculate_deadline(6*60*60, "Dec 24, 2010 12:00 PM").should == Time.parse("Dec 25, 2010 2:00 PM")
    end

  end

  context "original tests" do

    before do
      @hours = BusinessHours.new("9:00 AM", "3:00 PM")
      @hours.update :fri, "10:00 AM", "5:00 PM"
      @hours.update "Dec 24, 2010", "8:00 AM", "1:00 PM"
      @hours.closed :sun, :wed, "Dec 25, 2010"
    end

    it "should pass test #1" do
      @hours.calculate_deadline(2*60*60, "Jun 7, 2010 9:10 AM").should == Time.parse("Mon Jun 07 11:10:00 2010")
    end

    it "should pass test #2" do
      @hours.calculate_deadline(15*60, "Jun 8, 2010 2:48 PM").should == Time.parse("Thu Jun 10 09:03:00 2010")
    end

    it "should pass test #3" do
      @hours.calculate_deadline(7*60*60, "Dec 24, 2010 6:45 AM").should == Time.parse("Mon Dec 27 11:00:00 2010")
    end

  end

end

