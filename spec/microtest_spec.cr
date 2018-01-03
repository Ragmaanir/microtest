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

  test "test results" do
    result = microtest_test do
      describe Microtest do
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
    assert (2 ** 4) == ((a * a) * a) # false
    ==================================================
    (2 ** 4)                 => 16
    ((a * a) * a)            => 8
    EXC

    exc = results["MicrotestTest#long_assertion_failure_message"]["exception"]["message"].as_s

    assert uncolor(exc) == <<-EXC
    assert (2 ** 4) == ((long_name + long_name) + long_name) # false
    ==================================================
    (2 ** 4)
    16
    --------------------------------------------------
    ((long_name + long_name) + long_name)
    6
    --------------------------------------------------
    EXC

    exc = results["MicrotestTest#hide_literals_in_failure_message"]["exception"]["message"].as_s

    assert uncolor(exc) == %(assert "left" == "right" # false\n)

    assert results["MicrotestTest#skip_this"]["type"] == "Microtest::TestSkip"
    assert results["MicrotestTest#pending"]["type"] == "Microtest::TestSkip"
    assert results["MicrotestTest#pending_too"]["type"] == "Microtest::TestSkip"
    assert results["MicrotestTest#raise"]["type"] == "Microtest::TestFailure"
  end

  test "focusing" do
    result = microtest_test do
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

  test "before and after hook" do
    result = microtest_test do
      {{`cat spec/examples/hooks.cr`}}
    end

    assert result.success?

    results = result.json["results"]

    assert results["HooksTest#first"]["type"] == "Microtest::TestSuccess"
    assert results["HooksTest#second"]["type"] == "Microtest::TestSuccess"
  end

  test "error in before hook" do
    result = microtest_test do
      {{`cat spec/examples/before_hook_error.cr`}}
    end

    assert !result.success?
    assert !result.status.success?

    assert result.json["success"] == false
    assert result.json["aborted"] == true
    assert result.json["results"].as_h.empty?
  end

  test "error in after hook" do
    result = microtest_test do
      {{`cat spec/examples/after_hook_error.cr`}}
    end

    assert !result.success?
    assert !result.status.success?
    assert result.json["success"] == false
    assert result.json["aborted"] == true
    assert /Unexpected error/ === result.json["aborting_exception"]
    assert result.json["results"]["HooksTest#first"]["type"] == "Microtest::TestSuccess"
  end

  test "around hook" do
    result = microtest_test do
      {{`cat spec/examples/around_hook.cr`}}
    end

    assert result.json["results"]["AroundHookTest#first"]["type"] == "Microtest::TestSuccess"
    assert result.json["results"]["AroundHookTest#second"]["type"] == "Microtest::TestSuccess"
  end
end

# Make sure an empty describe block compiles
describe Array do
end
