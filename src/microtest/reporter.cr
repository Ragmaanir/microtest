module Microtest
  abstract class Reporter
    abstract def report(result : TestResult)

    def start
    end

    def finish(context : ExecutionContext)
    end
  end

  class ProgressReporter < Reporter

    CHARS = {
      dot: ["\u2022","\u2022"],
      ticks: ["\u2713","\u2715"]
    }

    def initialize(@chars = CHARS[:dot])
    end

    def report(result)
      case result
      when TestSuccess then print @chars[0].colorize(:green)
      when TestFailure then print @chars[1].colorize(:red)
      end
    end
  end

  class SummaryReporter < Reporter
    def report(result : TestResult)
    end

    def finish(context : ExecutionContext)
    end
  end
end
