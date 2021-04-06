module Microtest
  abstract class TestResult
    def self.from(
      suite_name : String,
      meth : TestMethod,
      duration : Time::Span,
      test_exc : TestException?,
      hook_exc : HookException?
    )
      case test_exc
      when AssertionFailure, UnexpectedError
        TestFailure.new(suite_name, meth.sanitized_name, duration, test_exc)
      when SkipException
        TestSkip.new(suite_name, meth.sanitized_name, duration, test_exc)
      when nil
        TestSuccess.new(suite_name, meth.sanitized_name, duration)
      else
        Microtest.bug("Unhandled internal exception: #{test_exc}")
      end
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
    getter exception : AssertionFailure | UnexpectedError

    def initialize(suite, test, duration : Time::Span, @exception)
      super(suite, test, duration)
    end

    def kind : Symbol
      :failure
    end
  end

  class TestSkip < TestResult
    getter exception : SkipException

    def initialize(suite, test, duration : Time::Span, @exception)
      super(suite, test, duration)
    end

    def kind : Symbol
      :skip
    end
  end

  class TestSuccess < TestResult
    def kind : Symbol
      :success
    end
  end
end
