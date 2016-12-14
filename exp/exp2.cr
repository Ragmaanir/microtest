require "./exp"

describe do
  test "xxx" do
    puts self.class.focused_tests
  end
end

class X
  puts "Yo"
end

puts X.focused_tests
puts X.new.test__xxx
