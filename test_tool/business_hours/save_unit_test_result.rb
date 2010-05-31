# save_unit_test_result.rb by ashbb
# usage: ruby save_unit_test_result.rb 01

require 'business_hours_test'

file = Dir["../../#{ARGV[0]}_*/business_hours.rb"].first

STDOUT.reopen(File.join(File.dirname(file), 'result.txt'), "w")
require file
