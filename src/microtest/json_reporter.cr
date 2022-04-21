require "json"

require "./formatter"

module Microtest
  class JsonSummaryReporter < Reporter
    def report(result : TestResult)
    end

    def finished(ctx : ExecutionContext)
      test_results = convert_test_results(ctx)

      ms = ctx.duration.total_milliseconds

      io << {
        using_focus:      Test.using_focus?,
        seed:             ctx.random_seed,
        success:          ctx.success?,
        aborted:          ctx.aborted?,
        manually_aborted: ctx.manually_aborted?,
        abortion:         if a = ctx.abortion_info
          {
            :suite       => a.test.suite.name,
            :test_name   => a.test.name,
            :test_method => a.test.method_name,
            :message     => a.exception.message,
            :backtrace   => a.exception.backtrace?,
          }
        end,
        total_count:    ctx.total_tests,
        executed_count: ctx.executed_tests,
        success_count:  ctx.total_success,
        skip_count:     ctx.total_skip,
        failure_count:  ctx.total_failure,
        total_duration: ms,
        results:        test_results,
      }.to_json
    end

    private def convert_test_results(ctx : ExecutionContext)
      ctx.results.reduce({} of String => Hash(String, String)) do |hash, res|
        entry = {
          :suite       => res.test.suite.name,
          :test_name   => res.test.name,
          :test_method => res.test.method_name,
          :type        => res.class.name,
          :duration    => res.duration.total_milliseconds,
        }

        if f = res.as?(TestFailure)
          json = case e = f.exception
                 when AssertionFailure then serialize_exception(e)
                 when UnexpectedError  then serialize_exception(e.exception)
                 end

          entry = entry.merge({:exception => json})
        end

        hash.merge({res.test.full_name => entry})
      end
    end

    def serialize_exception(e : Exception)
      {
        message:   e.to_s,
        class:     e.class.name,
        backtrace: e.backtrace?,
      }
    end
  end # JsonSummaryReporter
end
