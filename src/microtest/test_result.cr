module Microtest
  abstract class TestResult
    def self.failure(suite, test, error)
      TestFailure.new(suite, test, error)
    end

    def self.success(suite, test)
      TestSuccess.new(suite, test)
    end

    #getter suite : Test.class
    getter suite : String
    getter test : String

    def initialize(@suite, @test)
    end

    abstract def success?
  end

  class TestFailure < TestResult
    getter error

    def initialize(suite, test, @error)
      super(suite, test)
    end

    def success?
      false
    end

    def inspect(io)
      #io << "#{suite}.#{test}:"
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
