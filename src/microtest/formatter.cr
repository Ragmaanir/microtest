module Microtest
  module Formatter
    # format_large_number(1234567)
    # #=> "1,234,567"
    def self.format_large_number(number : Int32, separator : String = ",")
      number.to_s.reverse.gsub(/(\d{3})(?=.)/, "\\1#{separator}").reverse
    end

    class TimeUnit
      getter name : String
      getter full_name : String
      getter magnitude : Float64

      def initialize(@name, @full_name, magnitude : Int32 | Float64)
        @magnitude = magnitude.to_f64
      end

      def ==(other : TimeUnit)
        name == other.name
      end

      def ==(other)
        raise "not implemented for #{other.class}"
      end

      def to_s(io : IO)
        io << name
      end
    end

    TIME_UNITS = {
      day:         TimeUnit.new("d", "day", 24*60*60),
      hour:        TimeUnit.new("h", "hour", 60*60),
      minute:      TimeUnit.new("m", "minute", 60),
      second:      TimeUnit.new("s", "second", 1),
      millisecond: TimeUnit.new("ms", "millisecond", 10.0 ** -3),
      microsecond: TimeUnit.new("µs", "microsecond", 10.0 ** -6),
      nanosecond:  TimeUnit.new("ns", "nanosecond", 10.0 ** -9),
    }.to_h

    def self.format_duration(span : Time::Span)
      s = span.total_seconds

      magnitudes = [
        s / TIME_UNITS[:day].magnitude,
        s / TIME_UNITS[:hour].magnitude,
        s / TIME_UNITS[:minute].magnitude,
        s,
        s / TIME_UNITS[:millisecond].magnitude,
        s / TIME_UNITS[:microsecond].magnitude,
        s / TIME_UNITS[:nanosecond].magnitude,
      ].map(&.to_i)

      idx = magnitudes.index { |c| c > 0 } || (magnitudes.size - 1)

      unit = TIME_UNITS.values[idx]

      {Formatter.format_large_number(magnitudes[idx]), unit}
    end
  end
end
