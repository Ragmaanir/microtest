require "./duration"

module Microtest
  abstract class TestResult
    def self.failure(suite, test, duration, error)
      TestFailure.new(suite, test, duration, error)
    end

    def self.success(suite, test, duration)
      TestSuccess.new(suite, test, duration)
    end

    def self.skip(suite, test, duration, error)
      TestSkip.new(suite, test, duration, error)
    end

    # getter suite : Test.class
    getter suite : String
    getter test : String
    getter duration : Duration

    def initialize(@suite, @test, @duration)
    end

    def test_method
      [suite, test].join("#")
    end
  end

  class TestFailure < TestResult
    getter exception : Exception

    def initialize(suite, test, duration : Duration, @exception)
      super(suite, test, duration)
    end

    def inspect(io)
      io << "#{suite}.#{test}: #{error}"
    end
  end

  class TestSkip < TestResult
    getter exception : SkipException

    def initialize(suite, test, duration : Duration, @exception)
      super(suite, test, duration)
    end

    def inspect(io)
      io << "TestSkip"
    end
  end

  class TestSuccess < TestResult
    def inspect(io)
      io << "TestSuccess"
    end
  end
end
