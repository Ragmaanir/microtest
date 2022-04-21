require "./spec_helper"

describe Microtest::Reporter do
  test "progress reporter" do
    result = record_test([Microtest::ProgressReporter.new]) do
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

    dot = Microtest::TerminalReporter::DOTS[:success]

    assert result.stdout.includes?(dot.colorize(:red).to_s)
    assert result.stdout.includes?(dot.colorize(:yellow).to_s)
    assert result.stdout.includes?(dot.colorize(:green).to_s)
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

    assert result.stdout.includes?(bang.colorize(:yellow).to_s)
  end

  test "error list reporter" do
    result = record_test([Microtest::ErrorListReporter.new]) do
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

    output = uncolor(result.stdout)

    assert output.matches?(%r{skip: skip this one in SPEC: spec/test.cr:16})
    assert output.matches?(%r{# 1  MicrotestTest#error \nunexpected\n┏})
    assert output.matches?(%r{# 2  MicrotestTest#failure SPEC: spec/test.cr:\d+\n◆ assert 3 > 5})
  end

  test "error list reporter abortion" do
    result = record_test([Microtest::ErrorListReporter.new]) do
      describe Microtest do
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

    assert output.matches?(/ABORTED/)
    assert output.matches?(%r{┗ SPEC: spec/test.cr:\d+ before_hooks})
  end

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
