require "../spec_helper"

describe Microtest::SummaryReporter do
  test "summary reporter" do
    result = record_test([Microtest::SummaryReporter.new]) do
      describe Microtest do
        test "success" do
          assert true
        end

        test "failure" do
          assert 3 > 5
        end

        test "skip" do
          skip "skip this one"
        end
      end
    end

    assert !result.success?

    output = uncolor(result.stdout)
    assert output.matches?(%r{Executed 3/3 tests in \d+µs with seed 1})
    assert output.includes?("Success: 1, Skips: 1, Failures: 1")
  end

  test "summary reporter abortion" do
    result = record_test([Microtest::SummaryReporter.new]) do
      describe Microtest do
        before do
          raise "aborted"
        end

        test "failure" do
          assert false
        end
      end
    end

    assert !result.success?

    assert result.stdout.includes?("Test run was aborted by exception in hooks for \"failure\"")
  end
end
