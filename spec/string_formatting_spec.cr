require "./spec_helper"

describe Microtest::StringFormatting do
  include Microtest::StringFormatting

  test "format_large_number" do
    assert format_large_number(0) == "0"
    assert format_large_number(300) == "300"
    assert format_large_number(1300) == "1,300"
    assert format_large_number(100300) == "100,300"
    assert format_large_number(1234567) == "1,234,567"

    assert format_large_number(1300, "--") == "1--300"
  end
end
