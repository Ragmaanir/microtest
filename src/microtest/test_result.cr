module Microtest
  abstract class TestResult
    def self.from(test : TestMethod, duration : Time::Span, test_exc : TestException?)
      case test_exc
      when AssertionFailure, UnexpectedError
        TestFailure.new(test, duration, test_exc)
      when SkipException
        TestSkip.new(test, duration, test_exc)
      when nil
        TestSuccess.new(test, duration)
      else
        Microtest.bug("Unhandled internal exception: #{test_exc}")
      end
    end

    getter test : TestMethod
    getter duration : Time::Span

    def initialize(@test, @duration)
    end

    abstract def kind : Symbol
  end

  class TestFailure < TestResult
    getter exception : AssertionFailure | UnexpectedError

    def initialize(test, duration : Time::Span, @exception)
      super(test, duration)
    end

    def kind : Symbol
      :failure
    end
  end

  class TestSkip < TestResult
    getter exception : SkipException

    def initialize(test, duration : Time::Span, @exception)
      super(test, duration)
    end

    def kind : Symbol
      :skip
    end
  end

  class TestAbortion < TestResult
    def kind : Symbol
      :abortion
    end
  end

  class TestSuccess < TestResult
    def kind : Symbol
      :success
    end
  end
end
