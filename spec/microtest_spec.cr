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
    assert 1 == 5 - 4
  end
  
end
