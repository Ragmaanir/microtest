require "./spec_helper"

# require "../microtest"

# include Microtest::DSL

# Microtest.around do
#   # DB.transaction do
#   #   yield
#   # end
#   puts "before"
#   yield
#   puts "after"
# end

# Microtest.run!([
#   Microtest::DescriptionReporter.new,
# ] of Microtest::Reporter)

# FIXME this does not work as intended since:
# - github markdown does not support inline styles so `aha` styles are useless
# - could not find a markdown-to-png program
#
# => resort to gif/pngs captured by console
# def save_console_output(text, filename)
#   escaped = text.gsub("\n", "\\n")

#   cmd = "echo \"#{escaped}\" | aha  --black --no-header --title 'assertion failure' > #{filename}"

#   `#{cmd}`
# end

# def render_command(cmd, target, title = "", bg = "black")
#   full_cmd = <<-BASH
#     #{cmd} | aha --#{bg} --title "#{title}" > #{target}.html
#     wkhtmltoimage #{target}.html #{target}.png
#   BASH

#   puts system(full_cmd)
# end

# # convert text via "aha" to html, then convert html via wkhtmltoimage to png
# def save_console_output(text, target, title = "", bg = "black")
#   escaped = text.gsub("\n", "\\n")

#   full_cmd = <<-BASH
#     echo \"#{escaped}\" | aha --#{bg} --title "#{title}" > #{target}.html
#     wkhtmltoimage -q #{target}.html #{target}.png
#   BASH

#   system(full_cmd)
# end

# convert text via "aha" to html, then convert html via wkhtmltoimage to png
def save_console_output(result : MicrotestStdoutResult, target, title = "", bg = "black")
  escaped = result.to_s.gsub("\n", "\\n")

  full_cmd = <<-BASH
    echo \"#{escaped}\" | aha --#{bg} --title "#{title}" > #{target}.html
  BASH

  system(full_cmd)
end

describe WaterPumpExample do
  test "waterpump example" do
    res = microtest_test do
      {{`cat spec/examples/waterpump.cr`}}
    end

    assert res.json["results"].as_h.keys.sort == [
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
    save_console_output(res, "assets/assertion_failure")
  end
end

describe SummaryAndProgressRepoterExample do
  test "image" do
    res = reporter_test([Microtest::ProgressReporter.new, Microtest::ErrorListReporter.new, Microtest::SummaryReporter.new]) do
      {{`cat spec/examples/multiple_tests.cr`}}
    end

    assert !res.success?
    save_console_output(res, "assets/progress_reporter")
  end
end

describe SummaryAndDescriptionRepoterExample do
  test "image" do
    res = reporter_test([Microtest::DescriptionReporter.new, Microtest::ErrorListReporter.new, Microtest::SummaryReporter.new]) do
      {{`cat spec/examples/multiple_tests.cr`}}
    end

    assert !res.success?
    save_console_output(res, "assets/description_reporter")
  end
end

describe FocusExample do
  test "image" do
    res = reporter_test([Microtest::DescriptionReporter.new, Microtest::ErrorListReporter.new, Microtest::SummaryReporter.new]) do
      {{`cat spec/examples/focus.cr`}}
    end

    assert res.success?
    save_console_output(res, "assets/focus")
  end
end
