require "../spec_helper"

describe Microtest::ErrorListReporter do
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
    assert output.matches?(%r{# 1  MicrotestTest#error SPEC: spec/test.cr:12\nunexpected\n┏})
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
end
