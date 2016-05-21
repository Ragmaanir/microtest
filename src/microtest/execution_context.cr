module Microtest
  class ExecutionContext

    getter results : Array(TestResult)
    getter reporters : Array(Reporter)
    getter suites : Array(Test.class)

    def initialize(@reporters : Array(Reporter), @suites)
      @results = [] of TestResult
    end

    def errors : Array(TestFailure)
      results.map{ |res| res if res.is_a?(TestFailure) }.compact
    end

    def errors?
      errors.any?
    end

    def started
      reporters.each(&.started(self))
    end

    def finished
      reporters.each(&.finished(self))
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

    def total_tests
      suites.map(&.test_methods.size).sum
    end

    def total_success
      results.count(&.success?)
    end

    def total_failure
      results.count{|r| !r.success?}
    end

  end
end
