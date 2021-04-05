describe Hooks do
  before do
    @value = true
  end

  after do
    raise "After hook error"
  end

  test "first" do
    assert @value == true
    @value = false
  end
end
