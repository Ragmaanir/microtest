require "json"

require "./formatter"

module Microtest
  class JsonSummaryReporter < Reporter
    def report(result : TestResult)
    end

    def finished(ctx : ExecutionContext)
      test_results = convert_test_results(ctx)

      ms = ctx.duration.total_milliseconds

      puts({
        using_focus:        Test.using_focus?,
        seed:               ctx.random_seed,
        success:            !ctx.errors? && !ctx.aborted?,
        aborted:            ctx.aborted?,
        manually_aborted:   ctx.manually_aborted?,
        aborting_exception: ctx.aborting_exception.try(&.message),
        total_count:        ctx.total_tests,
        executed_count:     ctx.executed_tests,
        success_count:      ctx.total_success,
        skip_count:         ctx.total_skip,
        failure_count:      ctx.total_failure,
        total_duration:     ms,
        results:            test_results,
      }.to_json)
    end

    private def convert_test_results(ctx : ExecutionContext)
      ctx.results.reduce({} of String => Hash(String, String)) do |hash, res|
        entry = {
          :suite    => res.suite,
          :test     => res.test,
          :type     => res.class.name,
          :duration => res.duration.total_milliseconds,
        }

        entry = entry.merge(test_failure_exception_to_hash(res))

        hash.merge({"#{res.suite}##{res.test}" => entry})
      end
    end

    def test_failure_exception_to_hash(result : TestResult)
      hash = {} of String => String

      case result
      when TestFailure
        case e = result.exception
        when AssertionFailure
          hash = hash.merge({
            :exception => {
              message:   e.to_s,
              class:     e.class.name,
              backtrace: e.backtrace? ? e.backtrace : nil,
            },
          })
        when UnexpectedError
          hash = hash.merge({
            :exception => {
              message:   e.exception.to_s,
              class:     e.exception.class.name,
              backtrace: e.exception.backtrace? ? e.exception.backtrace : nil,
            },
          })
        else raise "BUG: unhandled exception"
        end
      end

      hash
    end
  end # JsonSummaryReporter
end
