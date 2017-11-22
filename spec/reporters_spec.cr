require "./spec_helper"

describe Microtest::Reporter do
  test "progress reporter" do
    result = reporter_test([Microtest::ProgressReporter.new]) do
      describe Microtest do
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
    end

    dot = Microtest::Helper::DOTS[:success]

    assert result.stdout.includes?(dot.colorize(:red).to_s)
    assert result.stdout.includes?(dot.colorize(:yellow).to_s)
    assert result.stdout.includes?(dot.colorize(:green).to_s)
  end
end

describe Microtest::JsonSummaryReporter do
  test "summary" do
    result = microtest_test do
      describe Summary do
        test "some test" do
          sleep 0.01
          assert true
        end
      end
    end

    json = result.json

    assert json["using_focus"] == false
    assert json["seed"].raw.is_a?(Int64)
    assert json["aborted"] == false
    assert json["aborting_exception"] == nil

    assert json["total_count"] == 1
    assert json["success_count"] == 1
    assert json["skip_count"] == 0
    assert json["failure_count"] == 0

    assert json["total_duration"].raw.is_a?(Float64)
    duration = json["total_duration"].raw.as(Float64)
    assert duration >= 8_i64
    assert duration <= 20_i64

    assert json["results"]["SummaryTest#some_test"]["duration"].raw.is_a?(Float64)
    duration = json["results"]["SummaryTest#some_test"]["duration"].raw.as(Float64)
    assert duration >= 8_i64
    assert duration <= 20_i64
  end

  test "test results" do
    result = microtest_test do
      describe Failure do
        test "pass" do
        end

        test "failure" do
          assert 3 > 5
        end

        test "unexpected" do
          raise "unexpected"
        end

        test "skip" do
          skip "skip this one"
        end
      end
    end

    json = result.json

    assert json["using_focus"] == false
    assert json["seed"].raw.is_a?(Int64)
    assert json["aborted"] == false
    assert json["aborting_exception"] == nil

    assert json["total_count"] == 4
    assert json["success_count"] == 1
    assert json["skip_count"] == 1
    assert json["failure_count"] == 2

    assert json["total_duration"].raw.is_a?(Float64)
    duration = json["total_duration"].raw.as(Float64)
    assert duration > 0_i64
    assert duration <= 100_i64

    assert json["results"]["FailureTest#pass"]["type"] == "Microtest::TestSuccess"
    assert json["results"]["FailureTest#failure"]["type"] == "Microtest::TestFailure"
    assert json["results"]["FailureTest#unexpected"]["type"] == "Microtest::TestFailure"
    assert json["results"]["FailureTest#skip"]["type"] == "Microtest::TestSkip"
  end
end
