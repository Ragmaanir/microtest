Microtest.before do
  puts "Microtest.before"
end

Microtest.after do
  puts "Microtest.after"
end

Microtest.around do
  puts "Microtest.around:start"
  yield
  puts "Microtest.around:end"
end

describe Test do
  before do
    puts "Test.before"
  end

  after do
    puts "Test.after"
  end

  around do
    puts "Test.around:start"
    yield
    puts "Test.around:end"
  end

  test "hook order" do
    puts "Test.test"
  end
end
