require 'day'
require 'business_hours' # renamed by ashbb
require 'time'
hours = BusinessHours.new("9:00 AM", "3:00 PM")

hours.update :sun, "9:00 AM", "10:45 AM"
hours.update :mon, "7:46 AM", "4:00 PM"
hours.update :thu, "10:00 AM", "12:01 PM"

hours.update "Dec 24, 2009", "11:00 AM", "2:00 PM"

hours.closed :tue, :wed, "Jan 21 2010", :fri, "Jan 23 2010"

hours.update "Dec 24, 2009", "2:00 AM", "2:30 PM"
hours.update "01/25/2010", "7:46 AM", "9:00 AM"
hours.update 'something', "7:46 AM", "9:00 AM" # will be parsed as 'today'
hours.update 1, "7:46 AM", "9:00 AM"
hours.update :mon, "7:46 AM", "4:00 PM"

# hours.display # => Used to display currently set business hours & special cases

hours.closed :tue

puts hours.calculate_deadline(2*60*60, "Jan 20, 2010 6:01 PM")
puts hours.calculate_deadline(60*60, "Jan 20, 2010 6:01 PM")
puts hours.calculate_deadline(15*60, "Jan 20, 2010 6:01 PM")
puts hours.calculate_deadline(2*60*60, "Jan 19, 2011 17:55 PM")

hours = BusinessHours.new("9:00 AM", "3:00 PM")
hours.closed :sun, :wed, "Dec 25 2010"
hours.update :fri, "10:00 AM", "5:00 PM"
hours.update "Dec 24, 2010", "8:00 AM", "1:00 PM"

puts hours.calculate_deadline(7*60*60, "Dec 24, 2010 6:45 AM")
