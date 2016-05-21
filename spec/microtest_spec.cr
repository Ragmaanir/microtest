require "./spec_helper"

describe Microtest do
  test "power asserts" do
    assert true == !false
    assert 1 > 0
  end

  test "fails" do
    assert true != !false
  end

  test "succeeds" do
    a = 1
    bob = 5

    assert bob == a - 4
  end

  test "raise" do
    raise "something"
  end
end
