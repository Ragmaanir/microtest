require "./spec_helper"

describe Microtest do
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

  test "test failing tests" do
    result = microtest_test do
      test "assertion failure message" do
        a = 2
        assert 2**4 == a * a * a
      end

      test "skip this" do
        skip "this is pending"
      end

      test "raise" do
        raise "something"
      end
    end

    exc = result["MicrotestTest#test__assertion_failure_message"]["exception"].as_s

    assert exc == <<-EXC
    2 ** 4           : 16
    a                : 2
    a * a            : 4
    (a * a) * a      : 8
    (2 ** 4) == ((a * a) * a) : false
    EXC

    assert result["MicrotestTest#test__skip_this"]["type"] == "Microtest::TestSkip"
    assert result["MicrotestTest#test__raise"]["type"] == "Microtest::TestFailure"
  end

  test "progress reporter" do
    result = reporter_test([Microtest::ProgressReporter.new], 1337.to_u32) do
      test "success" do
        assert true == true
      end

      test "failure" do
        assert 3 > 5
      end

      test "skip" do
        skip "skip this one"
      end
    end

    dot = Microtest::ProgressReporter::CHARS[:dot][0]

    assert result.includes?(dot.colorize(:red).to_s)
    assert result.includes?(dot.colorize(:yellow).to_s)
    assert result.includes?(dot.colorize(:green).to_s)
  end
end

# Make sure an empty describe block compiles
describe Array do
end
