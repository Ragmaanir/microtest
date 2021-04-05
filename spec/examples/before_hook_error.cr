describe Hooks do
  before do
    raise "Before hook error"
  end

  test "first" do
    assert true == true
  end
end
