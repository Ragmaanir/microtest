module Microtest
  abstract class TestException < Exception
    def initialize(msg : String)
      super(msg)
    end
  end

  class AssertionFailure < TestException
    getter file : String
    getter line : Int32

    def initialize(msg, @file, @line)
      super(msg)
    end
  end

  class SkipException < TestException
    getter file : String
    getter line : Int32

    def initialize(msg, @file, @line)
      super(msg)
    end
  end

  class UnexpectedError < TestException
    getter exception : Exception

    def initialize(@exception)
      super("Unexpected error: #{exception}")
    end
  end

  class HookException < Exception
    getter exception : Exception
    getter suite : String
    getter test : String

    def initialize(@suite, @test, @exception)
      super("Error in hook: #{exception}")
    end

    def test_method
      [suite, test].join("#")
    end
  end
end
