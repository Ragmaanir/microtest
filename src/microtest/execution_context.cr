module Microtest

  abstract class ExecutionContext
    getter results : Array(TestResult)
    getter reporters : Array(Reporter)

    abstract def record_result(result : TestResult)
    abstract def errors? : Bool
    def started
    end
    def ended
    end
  end

  class DefaultExecutionContext < ExecutionContext

    getter results : Array(TestResult)

    def initialize(@reporters : Array(Reporter))
      @results = [] of TestResult
    end

    def errors?
      results.any?{ |res| !res.success? }
    end

    def test_suite(cls)
      yield # FIXME
    end

    def test_case(name)
      yield # FIXME
    end

    def record_result(result : TestResult)
      @results << result
      @reporters.each(&.report(result))
      # FIXME
    end
  end

end
