module Microtest
  abstract class TestException < Exception
    getter file : String
    getter line : Int32

    def initialize(msg, @file, @line)
      super(msg)
    end
  end

  class AssertionFailure < TestException
  end

  class SkipException < TestException
  end

  class UnexpectedError < TestException
    getter exception : Exception
    getter suite : String
    getter test : String

    def initialize(@suite, @test, @exception)
      # super("Unexpected error in #{suite}##{test}: #{exception.message}")
      # super("Unexpected error: #{exception.message}", exception.file, exception.line)
      # XXX: suite, test, line
      super("Unexpected error: #{exception}", "unknown", 0)
    end
  end

  class HookException < Exception
    getter exception : Exception
    getter suite : String
    getter test : String

    def initialize(@suite, @test, @exception)
      super("Error in hook: #{exception}")
    end
  end
end
