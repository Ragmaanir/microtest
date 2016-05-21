module Microtest
  abstract class Reporter
    abstract def report(result : TestResult)

    def started(ctx : ExecutionContext)
    end

    def finished(ctx : ExecutionContext)
    end
  end

  class ProgressReporter < Reporter

    CHARS = {
      dot: ["\u2022","\u2022"],
      ticks: ["\u2713","\u2715"]
    }

    @chars : Array(String)

    def initialize(@chars = CHARS[:dot])
    end

    def report(result)
      case result
      when TestSuccess then print @chars[0].colorize(:green)
      when TestFailure then print @chars[1].colorize(:red)
      end
    end
  end

  class ErrorListReporter < Reporter
    include StringFormatting

    def report(result : TestResult)
    end

    def finished(ctx : ExecutionContext)
      ctx.errors.each_with_index do |error, i|
        print_error(i, error)
      end
    end

    private def print_error(number, error)
      #puts "|%03d| %s" % {number+1, "-"*25}
      puts
      case ex = error.exception
      when AssertionFailure
        puts format_string({:red, "%-3d" % (number+1), ex.file})
        puts ex.message
      when UnexpectedError
        puts format_string({:red, "%-3d" % (number+1), ex.message})
        puts ex.backtrace.join("\n")
      else raise "Invalid Exception"
      end
    end
  end

  class SummaryReporter < Reporter
    include StringFormatting

    def report(result : TestResult)
    end

    def finished(ctx : ExecutionContext)
      puts
      microseconds = ctx.results.map(&.duration).sum
      total = format_large_number(microseconds)
      puts format_string({:blue, "Executed #{ctx.total_tests} tests in #{total} microseconds"})
      puts format_string({:white,
        {:green, "Success: ", ctx.total_success},
        ", ",
        {(:red if ctx.total_failure > 0), "Failures: ", ctx.total_failure}
      })
    end

  end
end
