describe Hooks do
  before do
    @@value = true
  end

  after do
    assert @@value == false
  end

  test "first" do
    assert @@value == true
    @@value = false
  end

  test "second" do
    assert @@value == true
    @@value = false
  end
end
