require "./spec_helper"

describe NoColor do
  def failing_run(no_color : String?)
    record_test([Microtest::ProgressReporter.new, Microtest::ErrorListReporter.new, Microtest::SummaryReporter.new], env: {"NO_COLOR" => no_color}) do
      describe Microtest do
        test "failure" do
          assert 3 > 5
        end
      end
    end
  end

  test "colors output without NO_COLOR" do
    result = failing_run(nil)

    assert !result.success?
    assert result.stdout.includes?("\e[")
  end

  test "colors output when NO_COLOR is empty" do
    result = failing_run("")

    assert result.stdout.includes?("\e[")
  end

  test "writes no color codes when NO_COLOR is set" do
    result = failing_run("1")

    assert !result.success?
    assert result.stdout.includes?("assert 3 > 5")
    assert !result.stdout.includes?("\e[")
  end

  test "color default follows NO_COLOR" do
    assert Microtest::Termart.color_default?(nil)
    assert Microtest::Termart.color_default?("")
    assert !Microtest::Termart.color_default?("1")
    assert !Microtest::Termart.color_default?("false")
  end
end
