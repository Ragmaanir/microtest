require "../spec_helper"

describe Microtest::DescriptionReporter do
  test "description reporter" do
    result = record_test([Microtest::DescriptionReporter.new]) do
      describe DescriptionReporter do
        test "success" do
          assert true
        end

        test "failure" do
          assert 3 > 5
        end

        test "error" do
          raise "unexpected"
        end

        test "skip" do
          skip "skip this one"
        end
      end
    end

    assert !result.success?

    # dot = Microtest::TerminalReporter::DOTS[:success]

    output = uncolor(result.stdout)
    assert output.includes?("DescriptionReporterTest")
    assert output.matches?(%r{ ✓\s+\d+ .s success})
    assert output.matches?(%r{ ✕\s+\d+ .s error})
    assert output.matches?(%r{ ✕\s+\d+ .s failure})
    assert output.matches?(%r{ ✓\s+\d+ .s skip})
  end

  test "description reporter abortion" do
    result = record_test([Microtest::DescriptionReporter.new]) do
      describe DescriptionReporter do
        before do
          raise "ABORTED"
        end

        test "failure" do
          assert false
        end
      end
    end

    assert !result.success?

    output = uncolor(result.stdout)

    assert output.includes?("DescriptionReporterTest")
    assert output.matches?(%r{ 💥\s+\d+ .s failure})
  end
end
