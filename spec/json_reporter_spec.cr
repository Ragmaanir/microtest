require "./spec_helper"

describe Microtest::JsonSummaryReporter do
  test "summary" do
    seed = 1337

    result = record_test_json(seed) do
      describe Summary do
        test "some test" do
          sleep 1.millisecond
          assert true
        end
      end
    end

    json = result.json

    assert json["using_focus"] == false
    assert json["seed"].raw == seed
    assert json["aborted"] == false
    assert json["abortion"] == nil

    assert json["total_count"] == 1
    assert json["executed_count"] == 1
    assert json["success_count"] == 1
    assert json["skip_count"] == 0
    assert json["failure_count"] == 0

    assert json["total_duration"].raw.is_a?(Float64)
    duration = json["total_duration"].raw.as(Float64)
    assert duration >= 1_i64
    assert duration <= 100_i64

    assert json["results"]["SummaryTest#some_test"]["duration"].raw.is_a?(Float64)
    duration = json["results"]["SummaryTest#some_test"]["duration"].raw.as(Float64)
    assert duration >= 1_i64
    assert duration <= 100_i64
  end

  test "test results" do
    result = record_test_json do
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
    assert json["abortion"] == nil

    assert json["total_count"] == 4
    assert json["executed_count"] == 4
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
