require "./spec_helper"

describe Microtest::Formatter do
  alias F = Microtest::Formatter

  test "days" do
    span = Time::Span.new(days: 1)
    num, unit = F.format_duration(span)

    assert num == 1
    assert unit == F::TIME_UNITS[:day]
  end

  test "seconds" do
    span = Time::Span.new(seconds: 1)
    num, unit = F.format_duration(span)

    assert num == 1
    assert unit == F::TIME_UNITS[:second]
  end

  test "second from nanoseconds" do
    span = Time::Span.new(nanoseconds: 1_000_000_000)
    num, unit = F.format_duration(span)

    assert num == 1
    assert unit == F::TIME_UNITS[:second]
  end

  test "milliseconds" do
    span = Time::Span.new(nanoseconds: 1_000_000)
    num, unit = F.format_duration(span)

    assert num == 1
    assert unit == F::TIME_UNITS[:millisecond]
  end

  test "microseconds" do
    span = Time::Span.new(nanoseconds: 1_000)
    num, unit = F.format_duration(span)

    assert num == 1
    assert unit == F::TIME_UNITS[:microsecond]
  end

  test "microseconds" do
    span = Time::Span.new(nanoseconds: 1)
    num, unit = F.format_duration(span)

    assert num == 1
    assert unit == F::TIME_UNITS[:nanosecond]
  end
end
