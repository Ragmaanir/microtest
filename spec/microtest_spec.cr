require "./spec_helper"

describe Microtest do
  test "power asserts succeed" do
    assert true == !false
    assert 1 > 0
    assert "a" + "b" == "ab"
    assert [1] == [2 - 1]
    assert [] of Int32 == [] of Int32

    a = 1
    b = 5

    assert b == 4 + a
  end

  test "valid test-name" do
    assert true
  end

  test "assert_raises" do
    assert_raises(ArgumentError) do
      raise ArgumentError.new("expected exception")
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

  test "test results" do
    result = record_test_json do
      describe Microtest do
        test do # unnamed
        end

        test "assertion failure message" do
          a = 2
          assert 2**4 == a * a * a
        end

        test "long assertion failure message" do
          long_name = 2
          assert 2**4 == long_name + long_name + long_name
        end

        test "hide literals in failure message" do
          assert "left" == "right"
        end

        test "skip this" do
          skip "this is pending"
        end

        test "pending"

        pending "pending too" do
          raise ""
        end

        test "raise" do
          raise "something"
        end
      end
    end

    assert !result.success?

    results = result.json["results"]

    exc = results["MicrotestTest#assertion_failure_message"]["exception"]["message"].as_s

    assert uncolor(exc) == <<-EXC
    ┏ assert (2 ** 4) == ((a * a) * a)
    ┗ 16 == 8\n
    EXC

    exc = results["MicrotestTest#long_assertion_failure_message"]["exception"]["message"].as_s

    assert uncolor(exc) == <<-EXC
    ┏ assert (2 ** 4) == ((long_name + long_name) + long_name)
    ┗ 16 == 6\n
    EXC

    exc = results["MicrotestTest#hide_literals_in_failure_message"]["exception"]["message"].as_s

    assert uncolor(exc) == %[◆ assert "left" == "right"\n]

    assert results["MicrotestTest#skip_this"]["type"] == "Microtest::TestSkip"
    assert results["MicrotestTest#pending"]["type"] == "Microtest::TestSkip"
    assert results["MicrotestTest#pending_too"]["type"] == "Microtest::TestSkip"
    assert results["MicrotestTest#raise"]["type"] == "Microtest::TestFailure"
    assert results["MicrotestTest#unnamed_in_line_6"]["type"] == "Microtest::TestSuccess"
  end

  test "focusing" do
    result = record_test_json do
      describe Focus do
        test "in focus", :focus do
          assert true
        end

        test "not in focus" do
          assert false
        end
      end
    end

    assert result.success?

    results = result.json["results"]

    assert results["FocusTest#in_focus"]["type"] == "Microtest::TestSuccess"
    assert !results.as_h.has_key?("FocusTest#not_in_focus")
  end
end
