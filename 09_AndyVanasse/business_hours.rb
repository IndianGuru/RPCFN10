#!/usr/bin/ruby

require 'time'
require 'date'

class BusinessHours
  HourPosition = 3
  Weekdays = [:sun, :mon, :tue, :wed, :thu, :fri, :sat]

  def initialize(begin_time, end_time)
    standard_hours = build_hours_for_day(begin_time, end_time)

    @hours = {}
    Weekdays.each{|weekday| set_hours_for weekday.to_s, standard_hours }
  end

  def closed(*args)
    args.each do |day|
      set_hours_for day, nil
    end
  end

  def update(day, begin_time, end_time)
    nonstandard_hours = build_hours_for_day(begin_time, end_time)
    set_hours_for day, nonstandard_hours
  end

  def calculate_deadline( guaranteed_hours, start_time )
    remaining_time = guaranteed_hours
    set_start_time start_time

    until todays_hours_include_requested_time? && remaining_time.zero? do
      if todays_hours_include_requested_time?
        @current_time += remaining_time
        remaining_time = [0, @current_time-end_of_business(@current_date)].max
      end
      advance_to_start_of_next_business_day unless remaining_time.zero?
    end

    current_timestamp
  end

  private
    def current_timestamp
      Time.mktime(@current_date.year, @current_date.month, @current_date.day) + @current_time
    end

    def advance_to_start_of_next_business_day
      unless @current_time < start_of_business(@current_date)
        @current_date = next_business_day(@current_date) 
      end
      @current_time = start_of_business(@current_date)
    end

    def start_of_business( day )
      open_on?(day) ? @hours[ date_key(day) ].first : nil
    end

    def end_of_business( day )
      open_on?(day) ? @hours[ date_key(day) ].last : nil
    end

    def todays_hours_include_requested_time?
      open_on?(@current_date) && @hours[@current_date].include?(@current_time)
    end

    def set_start_time( time_string )
      @current_date = date_key time_string 
      @current_time = seconds_since_midnight time_string
    end

    def next_business_day( from_date )
      test_date = from_date + 1
      until open_on? test_date
        test_date += 1
      end 

      return test_date
    end

    def open_on?( a_date )
      assign_default_hours(a_date) unless @hours.include?( a_date )
      @hours[ a_date ]
    end

    def assign_default_hours( a_date )
      weekday = Weekdays[a_date.wday]
      set_hours_for a_date, @hours[weekday]
    end

    def set_hours_for( day, hours )
      @hours.merge!( date_key(day) => hours )
    end

    def date_key(day)
      case
        when day.is_a?(Date)               then day
        when day.is_a?(Symbol)             then day
        when Weekdays.include?(day.to_sym) then day.to_sym
        else                                    Date.parse(day)
      end
    end

    def build_hours_for_day(begin_time, end_time)
      hours = [seconds_since_midnight(begin_time), seconds_since_midnight(end_time)]
      Range.new hours.min, hours.max
    end

    def seconds_since_midnight(time_string)
      parsed_time = Time.parse(time_string)

      seconds = 0
      [parsed_time.sec, parsed_time.min, parsed_time.hour].each_with_index do |time_part, i| 
        time_part ||= 0
        seconds += ( time_part * (60 ** i) )
      end
      seconds
    end

end
=begin
hours = BusinessHours.new("9:00 AM", "3:00 PM")
hours.update :fri, "10:00 AM", "5:00 PM"
hours.update "Dec 24, 2010", "8:00 AM", "1:00 PM"
hours.closed :sun, :wed, "Dec 25, 2010"

puts hours.calculate_deadline(2*60*60, "Jun 7, 2010 9:10 AM") # => Mon Jun 07 11:10:00 2010
puts hours.calculate_deadline(15*60, "Jun 8, 2010 2:48 PM") # => Thu Jun 10 09:03:00 2010
puts hours.calculate_deadline(7*60*60, "Dec 24, 2010 6:45 AM") # => Mon Dec 27 11:00:00 2010
=end
