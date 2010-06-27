require 'time'

class BusinessHours
  DAYS = [:sun, :mon, :tue, :wed, :thu, :fri, :sat]
  
  def initialize(start_time, end_time)
    @normal_days = {}
    @holidays = {}

    DAYS.each do |day|
      set_hours day, start_time, end_time
    end
  end

  def update(day, start_time, end_time)
    set_hours day, start_time, end_time
  end

  def closed(*days)
    days.each do |day|
      if day.is_a? Symbol
        @normal_days[day] = {}
      else
        @holidays[day] = {}
      end
    end
  end

  def calculate_deadline(job_length, job_start)
    job_start = Time.parse(job_start) unless job_start.is_a? Time

    job_day = Time.parse(job_start.strftime("%Y-%m-%d"))

    hours= @holidays[job_day.strftime("%Y-%m-%d")] || @normal_days[DAYS[job_day.wday]]

    puts "Job Length:" + job_length.to_s
    puts "Job Start:" + job_start.to_s
    puts "Job Day:" + job_day.to_s
    puts "Hours:" + hours.to_s

    if hours[:start_time]
      start_time = [job_start - job_day, hours[:start_time]].max

      if hours[:end_time] - start_time > job_length
        #job will be completed today
        job_day + start_time + job_length
      else
        #not enough time today
        job_length -= hours[:end_time] - start_time unless start_time > hours[:end_time]
        calculate_deadline job_length, job_day + 24*60*60
      end

    else
      #closed for the day so continue to tomorrow
      calculate_deadline job_length, job_day + 24*60*60
    end
  end

  private

  def time_to_seconds(time)
    # store as number of seconds from midnight
    Time.parse(time) - Time.parse("00:00:00")
  end

  def set_hours(day, start_time, end_time)
    if day.is_a? Symbol
      @normal_days[day] = {:start_time => time_to_seconds(start_time).to_i, :end_time => time_to_seconds(end_time).to_i}
    else
      @holidays[Time.parse(day).strftime('%Y-%m-%d')] = {:start_time => time_to_seconds(start_time), :end_time => time_to_seconds(end_time)}
    end
  end

  def truncate_to_day(time)
      Time.parse(time.strftime("%Y-%m-%d"))
  end
end