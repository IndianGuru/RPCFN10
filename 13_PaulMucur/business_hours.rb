# RPCFN: Business Hours (#10)
# http://rubylearning.com/blog/2010/05/25/rpcfn-business-hours-10/
#
# Author:: Paul Mucur (mailto:mudge@mudge.name)

require 'date'
require 'time'

# This class represents a business schedule specifying opening and
# closing times throughout the year. Specific times can be set on
# a per day basis (e.g. open at 9:00 AM on Wednesdays) and on a per
# date basis (e.g. close at 1:00 PM on December 24th, 2010) as well
# as marking a day or date as being completely closed (e.g. closed
# on January 1st, 2011).
#
# A BusinessHours instance can then be used to calculate a deadline
# for a piece of work (e.g. given that work will take 3 hours and
# it will begin at 9:00 AM on June 5th, 2010, when will it be complete?)
class BusinessHours

  # Specify the valid day symbols and order them so that they can
  # be looked up using Date#wday.
  WEEKDAYS = [:sun, :mon, :tue, :wed, :thu, :fri, :sat].freeze

  # Exception raised when the user specifies an invalid day.
  class InvalidDay < StandardError; end

  # Exception raised when business is always closed.
  class NeverOpen < StandardError; end

  # Exception raised when the business isn't open enough to fulfil
  # a request.
  class NotOpenEnough < StandardError; end

  # Initialize a new BusinessHours object with the given
  # default opening and closing times as strings.
  #
  # e.g.
  #   hours = BusinessHours.new("9:00 AM", "3:00 PM")
  def initialize(default_opening, default_closing)

    # Don't parse the times yet as they will be parsed
    # when looking at specific days.
    @default = {
      :opening => default_opening,
      :closing => default_closing
    }

    # Store date-specific business hours.
    @dates = {}

    # Store day-specific business hours.
    @days = {}
    WEEKDAYS.each { |day| @days[day] = {} }
  end

  # Set specific opening and closing times for a day (identified by
  # using one of :sun, :mon, :tue, :wed, :thu, :fri or :sat) or a date.
  #
  # e.g.
  #   hours.update(:wed, "10:00 AM", "4:00 PM")
  #   hours.update("Dec 24, 2010", "9:00 AM", "1:00 PM")
  def update(day_or_date, opening, closing)

    # Similar to the defaults, don't parse opening and closing hours yet.
    business_hours = {
      :opening => opening,
      :closing => closing,
      :closed => false
    }

    # Determine whether day_or_date is a day (as specified by a symbol)
    # or a string date to be parsed.
    if day_or_date.is_a?(Symbol)
      if WEEKDAYS.include?(day_or_date)
        @days[day_or_date].update(business_hours)
      else
        raise InvalidDay, "day must be one of :#{WEEKDAYS.join(", :")}"
      end
    else
      parsed_time = Time.parse(day_or_date)
      date = Date.civil(parsed_time.year, parsed_time.month, parsed_time.day)
      @dates[date] ||= {}
      @dates[date].update(business_hours)
    end
    self
  end

  # Mark a specific day (identified by using one of :sun, :mon, :tue,
  # :wed, :thu, :fri, :sat) or date as being completely closed for
  # business.
  #
  # e.g.
  #   hours.closed(:wed, :fri, "Dec 25, 2010")
  def closed(*days_or_dates)
    days_or_dates.each do |day_or_date|
      if day_or_date.is_a?(Symbol)
        if WEEKDAYS.include?(day_or_date)
          @days[day_or_date].update(:closed => true)
        else
          raise InvalidDay, "day must be one of :#{WEEKDAYS.join(", :")}"
        end
      else
        parsed_time = Time.parse(day_or_date)
        date = Date.civil(parsed_time.year, parsed_time.month, parsed_time.day)
        @dates[date] ||= {}
        @dates[date].update(:closed => true)
      end
    end
    self
  end

  # Return the time that a job of interval_in_seconds seconds will be
  # completed given the specific start_time.
  #
  # This method will raise a NeverOpen exception if the business is
  # not open for duration of the specified request.
  #
  # If the business is open but not enough to complete the request,
  # a NotOpenEnough exception will be raised.
  #
  # e.g.
  #   hours.calculate_deadline(2*60*60, "Jun 7, 2010 9:10 AM")
  #   # => Mon Jun 07 11:10:00 2010
  def calculate_deadline(interval_in_seconds, start_time)
    parsed_time = Time.parse(start_time)
    date = Date.civil(parsed_time.year, parsed_time.month, parsed_time.day)

    # Calculate how many available seconds there are in the
    # specific dates but only if every day has been marked as
    # closed.
    available_seconds = if every_day_closed?
      @dates.inject(0) do |total, (day, hours)|
        if !hours[:closed] && day >= date

          # If this date is the start, calculate how long is left
          # from the start time otherwise use the default opening hours.
          opening = if day == date
            parsed_time
          else
            Time.parse(hours[:opening])
          end

          total + (Time.parse(hours[:closing]) - opening)
        else
          total
        end
      end
    end

    if every_day_closed? && !@dates.any? { |day, hours| !hours[:closed] && day >= date }

      # If every day is closed and there are no date-specific exceptions in
      # the future, raise an exception.
      raise NeverOpen, "the business is closed every day of the week"
    elsif every_day_closed? && available_seconds < interval_in_seconds

      # If every day is closed and there aren't enough seconds specified,
      # raise an exception.
      raise NotOpenEnough, "the business is not open enough to fulfil your request"
    else
      seconds_left = interval_in_seconds

      deadline_found = false

      # Until seconds_left has been completely depleted,
      # keep trying the next business day in sequence.
      until deadline_found

        # Keep this day's interval.
        todays_interval = seconds_left

        seconds_left -= remaining_interval(parsed_time)

        if seconds_left <= 0

          # The deadline is this day's opening hours plus
          # the remaining interval.
          deadline = parsed_time + todays_interval

          deadline_found = true
        else
          parsed_time = next_opening(parsed_time)
        end
      end

      deadline
    end
  end

  # Determine whether the business is open for a specific time
  # or not.
  #
  # e.g.
  #   hours.open?("Dec 25, 2010 10:00 AM")
  def open?(time)
    parsed_time = Time.parse(time)
    hours = hours_for(parsed_time)

    !hours[:closed] &&
      parsed_time > Time.parse(hours[:opening], parsed_time) &&
      parsed_time < Time.parse(hours[:closing], parsed_time)
  end

  # Give the number of business seconds remaining for a given
  # time.
  #
  # e.g.
  #   hours.remaining_interval("Dec 1, 2010 9:00 AM")
  #   # => 21600.0
  def remaining_interval(time)

    # Allow both strings and date/time objects to be passed in.
    parsed_time = if time.respond_to?(:year)
      time
    else
      Time.parse(time)
    end

    hours = hours_for(parsed_time)

    # Deal with hours that are closed.
    if hours[:closed]
      0
    else

      # If the specified time is before opening hours, use the opening
      # hours instead (as work can't be done before then).
      start_time = [parsed_time, Time.parse(hours[:opening], parsed_time)].max

      remaining_seconds = Time.parse(hours[:closing], parsed_time) - start_time

      # Don't return negative seconds.
      [remaining_seconds, 0].max
    end
  end

  # Return the next business day's opening time.
  #
  # e.g.
  #   hours.next_opening("Dec 1, 2010")
  #   # => Thu Dec 02 09:00:00 2010
  def next_opening(time)

    # Allow both strings and date/time objects to be passed in.
    parsed_time = if time.respond_to?(:year)
      time
    else
      Time.parse(time)
    end

    date = Date.civil(parsed_time.year, parsed_time.month, parsed_time.day)

    # Check that the business is open at least one day of the week.
    if every_day_closed? &&
        !@dates.any? { |day, hours| !hours[:closed] && day >= date }
      raise NeverOpen, "the business is closed every day of the week"
    else

      # First, try the day after the given one.
      next_date = date + 1

      next_opening_found = false

      # Until an open day is found, keep trying each day in sequence.
      until next_opening_found
        hours = hours_for(next_date)
        if !hours[:closed]
          next_opening = Time.parse(hours[:opening], next_date)
          next_opening_found = true
        else
          next_date += 1
        end
      end

      next_opening
    end
  end

  # Return whether or not every day of the week is marked as
  # closed.
  def every_day_closed?
    @days.all? { |day, hours| hours[:closed] }
  end

  private

  # Get the closed status, opening and closing times for
  # a specific Date object.
  #
  # e.g.
  #   hours_for(Date.today)
  #   # => {:opening=>"9:00 AM", :closing=>"3:00 PM", :closed=>false}
  def hours_for(parsed_time)
    date = Date.civil(parsed_time.year, parsed_time.month, parsed_time.day)
    day = WEEKDAYS[parsed_time.wday]

    hours = {}

    # First check if there are any date-specific rules.
    if @dates.has_key?(date)
      hours[:closed] = @dates[date][:closed]
      hours[:opening] = @dates[date][:opening]
      hours[:closing] = @dates[date][:closing]
    end

    # Then check for day-specific rules.
    if !@days[day].empty?
      hours[:closed] = @days[day][:closed] if hours[:closed].nil?
      hours[:opening] ||= @days[day][:opening]
      hours[:closing] ||= @days[day][:closing]
    end

    # Fall back to the default hours.
    hours[:closed] = false if hours[:closed].nil?
    hours[:opening] ||= @default[:opening]
    hours[:closing] ||= @default[:closing]

    hours
  end
end
