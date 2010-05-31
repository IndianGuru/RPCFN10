#!/usr/bin/env ruby

# require dependencies
require 'time'
require 'date'

class BusinessHours
  DAYS = [:sun, :mon, :tue, :wed, :thu, :fri, :sat]
  ONE_DAY = 24*60*60

  class Day
    attr_accessor :opening, :closing, :date

    def initialize(opening_time, closing_time, date=nil)
      self.update(opening_time, closing_time, date)
    end

    def close
      self.opening, self.closing = nil, nil
    end

    def closed?
      self.opening.nil?
    end

    def update(opening_time, closing_time, date=nil)
      self.opening, self.closing, self.date = opening_time, closing_time, date
    end
  end

  attr_accessor :business_hours, :exceptions

  def initialize(opening_time, closing_time)
    self.business_hours, self.exceptions = {}, {}

    DAYS.each do |day|
      self.business_hours[day] = Day.new(opening_time, closing_time)
    end
  end

  def update(day, opening_time, closing_time)
    if day.is_a?(Symbol)
      self.business_hours[day].update(opening_time, closing_time)
    else # string expected, it's a special date case
      date = Date.parse(day)
      self.exceptions[date.to_s] = Day.new(opening_time, closing_time)
    end
  end

  def closed(*days)
    days.each do |day|
      if day.is_a?(Symbol)
        self.business_hours[day].close
      else
        date = Date.parse(day)
        self.exceptions[date.to_s] = Day.new(nil, nil)
      end
    end
  end

  def calculate_deadline(interval, starting_time)
    start_at = time = Time.parse(starting_time)
    date = time.strftime('%Y-%m-%d')
    weekday = time.strftime('%a').downcase.to_sym

    remaining_time = interval
    while remaining_time.is_a?(Integer) && remaining_time > 0
      d = self.exceptions[date] || self.business_hours[weekday]
      unless d.closed?
        from = Time.parse(date + ' ' + d.opening)
        to = Time.parse(date + ' ' + d.closing)
        if (from..to).include?(start_at)
          from = start_at
        end
        remaining_time = deduct(remaining_time, (from..to))
      end

      return remaining_time unless remaining_time.is_a?(Integer)

      time = time + ONE_DAY
      date = time.strftime('%Y-%m-%d')
      weekday = time.strftime('%a').downcase.to_sym
    end
  end

  private

  def deduct(count, range)
    total = (range.last-range.first).to_i
    if count >= total
      count - total
    else
      range.first + count
    end
  end

end