module Microtest
  class SummaryReporter < TerminalReporter
    def report(result : TestResult)
    end

    def started(ctx : ExecutionContext)
      @started_at = Time.local
    end

    def finished(ctx : ExecutionContext)
      total, unit = Formatter.format_duration(ctx.duration)

      if ctx.focus?
        write("USING FOCUS:", bg: RED)
        write(" ")
      end

      fg = LIGHT_BLUE

      write("Executed", fg: fg)
      write(" #{ctx.executed_tests}/#{ctx.total_tests} ", fg: (ctx.executed_tests < ctx.total_tests) ? RED : fg)
      write("tests in #{total}#{unit} with seed #{ctx.random_seed}", fg: fg)
      br

      write("Success: ", ctx.total_success, fg: (GREEN if ctx.total_success > 0))
      write(", ")

      write("Skips: ", ctx.total_skip, fg: (YELLOW if ctx.total_skip > 0))
      write(", ")

      write("Failures: ", ctx.total_failure, fg: (RED if ctx.total_failure > 0))
      br

      if ctx.manually_aborted?
        br
        writeln("Test run was aborted manually", fg: WHITE, bg: RED)
      elsif a = ctx.abortion_info
        br
        writeln("Test run was aborted by exception in hooks for ", a.test.name.inspect, fg: WHITE, bg: RED)
      end

      br
    end
  end
end
