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
end
