describe Hooks do
  before do
    @value = true
  end

  after do
    assert @value == true
  end

  test "first" do
    assert @value == true
    @value = false
  end
end
