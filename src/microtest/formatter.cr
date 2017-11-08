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

      def integer_dividable?(seconds : Float64)
        (seconds / magnitude).to_i > 0
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

    # format_duration(15.milliseconds)) #=> {15, :millisecond}
    # format_duration(1000.milliseconds)) #=> {1, :second}
    def self.format_duration(span : Time::Span)
      s = span.total_seconds

      # find first time unit that has an integer part bigger than zero, or use nanosecond as unit
      unit = TIME_UNITS.values.find { |unit| unit.integer_dividable?(s) } || TIME_UNITS[:nanosecond]

      time = (s / unit.magnitude).to_i

      {time, unit}
    end

    DEFAULT_DURATION_COLORING_SCALE = [:dark_gray, :yellow, :red, :light_red]

    def self.colorize_duration(duration : Time::Span, threshold : Time::Span, colors = DEFAULT_DURATION_COLORING_SCALE)
      time, unit = Formatter.format_duration(duration)
      _, threshold_unit = Formatter.format_duration(threshold)

      if duration > threshold
        idx = 3.times.find { |i| threshold * (10**i) > duration } || 3
        color = colors[idx]
      else
        color = colors.first
      end

      ("%4s %-2s" % [time, unit]).colorize(color)
    end
  end
end
