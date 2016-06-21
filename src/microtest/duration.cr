module Microtest
  class Duration
    include Comparable(Duration)

    getter milliseconds : Int32

    def self.milliseconds(millis)
      new(millis)
    end

    def self.zero
      new(0)
    end

    private def initialize(@milliseconds)
    end

    def in_seconds
      milliseconds / 1000
    end

    def <=>(other : Duration)
      milliseconds <=> other.milliseconds
    end

    def +(other : T)
      Duration.milliseconds(milliseconds + other.milliseconds)
    end
  end
end
