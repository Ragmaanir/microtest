describe Hooks do
  before do
    raise "error"
  end

  test "first" do
    assert true == true
  end
end
