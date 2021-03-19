require "./spec_helper"

describe WaterPumpExample do
  test "waterpump example" do
    res = microtest_test do
      {{`cat spec/examples/waterpump.cr`}}
    end

    assert res.json["results"].as_h.keys.sort! == [
      "MyLib::WaterPumpTest#and_this_one_too_since_it_is_focused_also",
      "MyLib::WaterPumpTest#only_run_this_focused_test",
    ].sort

    assert res.json["results"]["MyLib::WaterPumpTest#and_this_one_too_since_it_is_focused_also"]["type"] == "Microtest::TestSuccess"
    assert res.json["results"]["MyLib::WaterPumpTest#only_run_this_focused_test"]["type"] == "Microtest::TestSuccess"
  end
end

describe AssertionFailureExample do
  test "assertion failure example" do
    res = reporter_test([Microtest::ErrorListReporter.new]) do
      {{`cat spec/examples/assertion_failure.cr`}}
    end

    assert !res.success?

    Helpers.save_console_output(res, "assertion_failure") if generate_assets?
  end
end

describe SummaryAndProgressRepoterExample do
  test "image" do
    res = reporter_test([Microtest::ProgressReporter.new, Microtest::ErrorListReporter.new, Microtest::SummaryReporter.new]) do
      {{`cat spec/examples/multiple_tests.cr`}}
    end

    assert !res.success?
    Helpers.save_console_output(res, "progress_reporter") if generate_assets?
  end
end

describe SummaryAndDescriptionRepoterExample do
  test "image" do
    res = reporter_test([Microtest::DescriptionReporter.new, Microtest::ErrorListReporter.new, Microtest::SummaryReporter.new]) do
      {{`cat spec/examples/multiple_tests.cr`}}
    end

    assert !res.success?
    Helpers.save_console_output(res, "description_reporter") if generate_assets?
  end
end

describe FocusExample do
  test "image" do
    res = reporter_test([Microtest::DescriptionReporter.new, Microtest::ErrorListReporter.new, Microtest::SummaryReporter.new]) do
      {{`cat spec/examples/focus.cr`}}
    end

    assert res.success?
    Helpers.save_console_output(res, "focus") if generate_assets?
  end
end
