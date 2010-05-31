# encoding: utf-8
require 'time'

class BusinessHours
  CLOSED = []

  def initialize(default_open_hour, default_close_hour)
    @open_close = {}
    @default_open_close = [default_open_hour, default_close_hour]
  end

  def update(day, open, close)
    @open_close[day] = [open, close]
  end

  def closed(*days)
    days.each { |day| @open_close[day] = CLOSED }
  end

  def calculate_deadline(time_to_complete, start_time)
    current_time = Time.parse(start_time)
    current_time += time_until_open(current_time)
    while true
      work_time = work_time(current_time)
      if time_to_complete < work_time
        current_time += time_to_complete
        break
      else
        current_time += work_time + time_to_next_open(current_time)
        time_to_complete -= work_time
      end
    end
    current_time
  end

  private
  # returns the open and close times for the specified date or an empty array if closed on that date
  def open_close_times(date)
    open_close = @open_close[as_string(date)] || @open_close[as_sym(date)] || @default_open_close
    open_close.collect { |h| Time.parse("#{as_string(date)} #{h}") }
  end

  # the length of time available during a specified day to do work
  # e.g., there are 6 hours available if we open at 9:00 AM, close at 3:00 PM, and the item was dropped off at 9:00 AM
  #       there are 5 hours available if we open at 9:00 AM, close at 3:00 PM, and the item was dropped off at 10:00 AM
  def work_time(date)
    open, closed = open_close_times(date)
    closed - open - time_already_open(date)
  end

  # the length of time from the specified time until we open
  # e.g., if the specified time is 6:00 AM and we open at 8:30 AM, then the time until open is 2 hours and 30 minutes
  def time_until_open(date)
    open = open_close_times(date).first
    open - date > 0 ? open - date : 0
  end

  # the length of time from when we opened to the specified time
  # e.g., if we opened at 9:00 AM and the time specified is 9:30 AM, then the time already open is 30 minutes
  def time_already_open(date)
    open = open_close_times(date).first
    date - open > 0 ? date - open : 0
  end

  # the length of time from the close of the working day on the specified date until the next opening
  # e.g., if we close at 5:00 PM on May 26 and don't open again until 9:00 AM on May 28, then the time to next open is 40 hours
  def time_to_next_open(date)
    closed_at = open_close_times(date).last
    date = next_day(date)
    while open_close_times(date) == CLOSED
      date = next_day(date)
    end
    open_at = open_close_times(date).first
    open_at - closed_at
  end

  # the date in our string format: e.g., Monday April 05, 2010 9:00 AM = Apr 05, 2010
  def as_string(date)
    date.strftime("%b %d, %Y")
  end

  # the date in our short format: e.g., Monday April 05, 2010 9:00 AM = :mon
  def as_sym(date)
    date.strftime("%a").downcase.to_sym
  end

  # advance the specified date by 24 hours
  def next_day(date)
    date + (60 * 60 * 24)
  end
end
