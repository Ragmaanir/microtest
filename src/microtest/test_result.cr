module Microtest
  abstract class TestResult
    def self.failure(suite, test, duration, error)
      TestFailure.new(suite, test, duration, error)
    end

    def self.success(suite, test, duration)
      TestSuccess.new(suite, test, duration)
    end

    # getter suite : Test.class
    getter suite : String
    getter test : String
    getter duration : Int64

    def initialize(@suite, @test, @duration)
    end

    abstract def success?
  end

  class TestFailure < TestResult
    getter exception : Exception

    def initialize(suite, test, duration, @exception)
      super(suite, test, duration)
    end

    def success?
      false
    end

    def inspect(io)
      io << "#{suite}.#{test}: #{error}"
    end
  end

  class TestSuccess < TestResult
    def success?
      true
    end

    def inspect(io)
      io << "TestSuccess"
    end
  end
end
