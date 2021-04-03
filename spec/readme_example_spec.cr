require "./spec_helper"

describe WaterPumpExample do
  test "waterpump example" do
    res = microtest_test do
      {{`cat spec/examples/waterpump.cr`}}
    end

    assert res.json["results"].as_h.keys.sort! == [
      "WaterPumpTest#enabling",
      "WaterPumpTest#pump_speed",
      "WaterPumpTest#test_using_annotations",
      "WaterPumpTest#this_one_is_pending_even_though_it_has_a_body",
      "WaterPumpTest#this_one_is_pending_since_it_got_no_body",
    ].sort

    assert res.json["results"]["WaterPumpTest#enabling"]["type"] == "Microtest::TestSuccess"
    assert res.json["results"]["WaterPumpTest#pump_speed"]["type"] == "Microtest::TestSuccess"
    assert res.json["results"]["WaterPumpTest#test_using_annotations"]["type"] == "Microtest::TestSkip"
    assert res.json["results"]["WaterPumpTest#this_one_is_pending_even_though_it_has_a_body"]["type"] == "Microtest::TestSkip"
    assert res.json["results"]["WaterPumpTest#this_one_is_pending_since_it_got_no_body"]["type"] == "Microtest::TestSkip"
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
