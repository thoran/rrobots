require_relative 'test_helper'
require "rrobots"

# class TestRRobots < Minitest::Test
#   def test_sanity
#     flunk "Write tests which will run or I will kneecap youse."
#   end
# end

test_files = Dir["#{File.dirname(__FILE__)}/*"]
test_files.reject!{|test_file| test_file =~ /helper/ || test_file =~ /rrobots/}
test_files.each do |test_file|
  require test_file
end
