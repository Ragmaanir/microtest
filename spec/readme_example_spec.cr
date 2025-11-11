require "./spec_helper"

describe WaterPumpExample do
  test "waterpump example" do
    res = record_test_json do
      {{ read_file("#{__DIR__}/examples/waterpump.cr").id }}
    end

    assert res.json["results"].as_h.keys.sort! == [
      "WaterPumpTest#enabling",
      "WaterPumpTest#pump_speed",
      "WaterPumpTest#this_one_is_pending_even_though_it_has_a_body",
      "WaterPumpTest#this_one_is_pending_since_it_got_no_body",
    ].sort

    assert res.json["results"]["WaterPumpTest#enabling"]["type"] == "Microtest::TestSuccess"
    assert res.json["results"]["WaterPumpTest#pump_speed"]["type"] == "Microtest::TestSuccess"
    assert res.json["results"]["WaterPumpTest#this_one_is_pending_even_though_it_has_a_body"]["type"] == "Microtest::TestSkip"
    assert res.json["results"]["WaterPumpTest#this_one_is_pending_since_it_got_no_body"]["type"] == "Microtest::TestSkip"
  end
end

describe AssertionFailureExample do
  test "assertion failure example" do
    res = record_test([Microtest::ErrorListReporter.new]) do
      {{ read_file("#{__DIR__}/examples/assertion_failure.cr").id }}
    end

    assert !res.success?

    Helpers.save_console_output(res, "assertion_failure") if generate_assets?
  end
end

describe SummaryAndProgressRepoterExample do
  test "image" do
    res = record_test([Microtest::ProgressReporter.new, Microtest::ErrorListReporter.new, Microtest::SummaryReporter.new]) do
      {{ read_file("#{__DIR__}/examples/multiple_tests.cr").id }}
    end

    assert !res.success?
    Helpers.save_console_output(res, "progress_reporter") if generate_assets?
  end
end

describe SummaryAndDescriptionRepoterExample do
  test "image" do
    res = record_test([Microtest::DescriptionReporter.new, Microtest::ErrorListReporter.new, Microtest::SummaryReporter.new]) do
      {{ read_file("#{__DIR__}/examples/multiple_tests.cr").id }}
    end

    assert !res.success?
    Helpers.save_console_output(res, "description_reporter") if generate_assets?
  end
end

describe FocusExample do
  test "image" do
    res = record_test([Microtest::DescriptionReporter.new, Microtest::ErrorListReporter.new, Microtest::SummaryReporter.new]) do
      {{ read_file("#{__DIR__}/examples/focus.cr").id }}
    end

    assert res.success?
    Helpers.save_console_output(res, "focus") if generate_assets?
  end
end
