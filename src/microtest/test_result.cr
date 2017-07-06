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
    getter duration : Time::Span

    def initialize(@suite, @test, @duration)
    end

    def test_method
      [suite, test].join("#")
    end

    abstract def kind : Symbol
  end

  class TestFailure < TestResult
    getter exception : Exception

    def initialize(suite, test, duration : Time::Span, @exception)
      super(suite, test, duration)
    end

    def kind
      :failure
    end

    def inspect(io)
      io << "#{suite}.#{test}: #{exception}"
    end
  end

  class TestSkip < TestResult
    getter exception : SkipException

    def initialize(suite, test, duration : Time::Span, @exception)
      super(suite, test, duration)
    end

    def kind
      :skip
    end

    def inspect(io)
      io << "TestSkip"
    end
  end

  class TestSuccess < TestResult
    def kind
      :success
    end

    def inspect(io)
      io << "TestSuccess"
    end
  end
end
