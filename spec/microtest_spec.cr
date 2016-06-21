require "./spec_helper"

describe Microtest do
  test "raise" do
    raise "something"
  end

  test "power asserts" do
    assert true == !false
    assert 1 > 0
  end

  test "fails" do
    assert 2**5 == 4 * 2**4
  end

  test "succeeds" do
    a = 1
    bob = 5

    assert bob == 4 + a
  end
end
