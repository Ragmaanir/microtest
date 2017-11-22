module Microtest
  class StandardException < Exception
    getter file : String
    getter line : Int32

    def initialize(msg, @file, @line)
      super(msg)
    end
  end

  class AssertionFailure < StandardException
  end

  class SkipException < StandardException
  end

  class UnexpectedError < StandardException
    getter exception : Exception
    getter suite : String
    getter test : String

    def initialize(@suite, @test, @exception)
      # super("Unexpected error in #{suite}##{test}: #{exception.message}")
      # super("Unexpected error: #{exception.message}", exception.file, exception.line)
      super("Unexpected error: #{exception}", "unknown", 0)
    end
  end

  class HookException < UnexpectedError
    getter test_exception : StandardException | Symbol | Nil

    def initialize(suite, test, exception, @test_exception)
      super(suite, test, exception)
    end
  end

  class FatalException < Exception
  end
end
