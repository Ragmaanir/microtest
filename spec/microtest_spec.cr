require "./spec_helper"

describe Microtest do
  test "raise" do
    raise "something"
  end

  test "fails" do
    a = 2
    assert 2**4 == a * a * a
  end

  test "power asserts" do
    assert true == !false
    assert 1 > 0
  end

  test "succeeds" do
    a = 1
    bob = 5

    assert bob == 4 + a
  end

  test "valid test-name" do
    assert true
  end

  test "assert_raises" do
    assert_raises(ArgumentError) do
      raise ArgumentError.new("bob")
    end

    assert_raises(Microtest::AssertionFailure) do
      assert_raises(ArgumentError) do
      end
    end

    assert_raises(Microtest::AssertionFailure) do
      assert_raises(ArgumentError) do
        raise "unexpected exception"
      end
    end
  end

  test "skip this" do
    skip "this is pending"
  end
end

# Make sure an empty describe block compiles
describe Array do
end
