module Microtest
  class AbortionInfo
    getter exception : Exception
    getter test : TestMethod

    def initialize(@test, @exception)
    end
  end

  class ExecutionContext
    getter results : Array(TestResult)
    getter reporters : Array(Reporter)
    getter suites : Array(Test.class)
    getter random_seed : UInt32
    getter random : Random
    getter abortion_info : AbortionInfo? = nil
    getter? manually_aborted : Bool = false
    getter started_at : Time = Time.local
    getter! ended_at : Time
    @focus : Bool

    def initialize(@reporters : Array(Reporter), @suites, @random_seed : UInt32 = Random.new_seed)
      @results = [] of TestResult
      @random = Random.new(@random_seed)
      @focus = @suites.any?(&.using_focus?)
    end

    def focus?
      @focus
    end

    def duration
      ended_at - started_at
    end

    def failures : Array(TestFailure)
      results.compact_map(&.as?(TestFailure))
    end

    def failures?
      !failures.empty?
    end

    def success?
      !(failures? || aborted?)
    end

    def manually_abort!
      @manually_aborted = true
    end

    def aborted?
      !!abortion_info
    end

    def halted?
      manually_aborted? || aborted?
    end

    def skips
      results.compact_map(&.as?(TestSkip))
    end

    def started
      reporters.each(&.started(self))
    end

    def finished
      @ended_at = Time.local
      reporters.each(&.finished(self))
    end

    def test_suite(name : String, &)
      reporters.each(&.suite_started(self, name))
      yield
      reporters.each(&.suite_finished(self, name))
    end

    def record_result(meth : TestMethod, duration : Time::Span, exc : TestException?)
      record_result(TestResult.from(meth, duration, exc))
    end

    def record_abortion(meth : TestMethod, duration : Time::Span)
      record_result(TestAbortion.new(meth, duration))
    end

    private def record_result(result : TestResult)
      @results << result
      @reporters.each(&.report(result))
    end

    def abort!(info : AbortionInfo)
      @reporters.each(&.abort(self, info))
      @abortion_info = info
    end

    def total_tests
      suites.sum(&.test_methods.size)
    end

    def executed_tests
      results.size
    end

    def total_success
      results.count(&.as?(TestSuccess))
    end

    def total_failure
      results.count(&.as?(TestFailure))
    end

    def total_skip
      results.count(&.as?(TestSkip))
    end
  end
end
