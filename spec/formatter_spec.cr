require "./spec_helper"

describe Microtest::Formatter do
  alias F = Microtest::Formatter

  test "days" do
    span = Time::Span.new(1, 0, 0, 0)
    num, unit = F.format_duration(span)

    assert num == 1
    assert unit == F::TIME_UNITS[:day]
  end

  test "seconds" do
    span = Time::Span.new(0, 0, 0, 1)
    num, unit = F.format_duration(span)

    assert num == 1
    assert unit == F::TIME_UNITS[:second]
  end

  test "second from nanoseconds" do
    span = Time::Span.new(0, 0, 0, 0, 1_000_000_000)
    num, unit = F.format_duration(span)

    assert num == 1
    assert unit == F::TIME_UNITS[:second]
  end

  test "milliseconds" do
    span = Time::Span.new(0, 0, 0, 0, 1_000_000)
    num, unit = F.format_duration(span)

    assert num == 1
    assert unit == F::TIME_UNITS[:millisecond]
  end

  test "microseconds" do
    span = Time::Span.new(0, 0, 0, 0, 1_000)
    num, unit = F.format_duration(span)

    assert num == 1
    assert unit == F::TIME_UNITS[:microsecond]
  end

  test "microseconds" do
    span = Time::Span.new(0, 0, 0, 0, 1)
    num, unit = F.format_duration(span)

    assert num == 1
    assert unit == F::TIME_UNITS[:nanosecond]
  end
end
