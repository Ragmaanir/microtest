require "../spec_helper"

describe Microtest::ProgressReporter do
  test "progress reporter" do
    result = record_test([Microtest::ProgressReporter.new]) do
      describe Microtest do
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

    dot = Microtest::TerminalReporter::DOTS[:success]

    assert result.stdout == [
      dot.colorize(GREEN),
      dot.colorize(RED),
      dot.colorize(YELLOW),
      dot.colorize(RED),
      "\n\n",
    ].join
  end

  test "progress reporter abortion" do
    result = record_test([Microtest::ProgressReporter.new]) do
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

    bang = Microtest::TerminalReporter::DOTS[:abortion]

    assert result.stdout.includes?(bang.colorize(YELLOW).to_s)
  end
end
