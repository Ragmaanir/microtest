module Microtest
  abstract class Reporter
    getter io : IO

    def initialize(@io)
    end

    abstract def report(result : TestResult)

    def started(ctx : ExecutionContext)
    end

    def finished(ctx : ExecutionContext)
    end

    private def puts(*args)
      io.puts(*args)
    end
  end

  class ProgressReporter < Reporter
    CHARS = {
      dot:   ["\u2022", "\u2022"],
      ticks: ["\u2713", "\u2715"],
    }

    @chars : Array(String)

    def initialize(@chars = CHARS[:dot], io = STDOUT)
      super(io)
    end

    def report(result)
      case result
      when TestSuccess then print @chars[0].colorize(:green)
      when TestFailure then print @chars[1].colorize(:red)
      end
    end

    def finished(ctx : ExecutionContext)
      puts
    end
  end

  class ErrorListReporter < Reporter
    include StringFormatting

    def initialize(io = STDOUT)
      super(io)
    end

    def report(result : TestResult)
    end

    def finished(ctx : ExecutionContext)
      ctx.errors.each_with_index do |error, i|
        print_error(i, error)
      end
    end

    private def print_error(number, error)
      # puts "|%03d| %s" % {number+1, "-"*25}
      case ex = error.exception
      when AssertionFailure
        puts format_string({:red, "# %-3d" % (number + 1), error.test_method})
        puts ex.message
      when UnexpectedError
        puts format_string({:red, "# %-3d" % (number + 1), ex.message})
        if ex.backtrace?
          puts ex.backtrace.join("\n")
        end
      else raise "Invalid Exception"
      end

      puts
    end
  end

  class SummaryReporter < Reporter
    include StringFormatting

    def initialize(io = STDOUT)
      super(io)
    end

    def report(result : TestResult)
    end

    def finished(ctx : ExecutionContext)
      ms = ctx.results.map(&.duration).sum.milliseconds
      total = format_large_number(ms)
      puts format_string({:blue, "Executed #{ctx.total_tests} tests in #{total} milliseconds with seed #{ctx.random_seed}"})
      puts format_string({:white,
        {:green, "Success: ", ctx.total_success},
        ", ",
        {(:red if ctx.total_failure > 0), "Failures: ", ctx.total_failure},
      })
      puts
    end
  end

  class SlowTestsReporter < Reporter
    include StringFormatting

    getter count : Int32
    getter threshold : Duration

    def initialize(@count = 10, @threshold = Duration.milliseconds(1), io = STDOUT)
      super(io)
    end

    def report(result : TestResult)
    end

    def finished(ctx : ExecutionContext)
      res = ctx.results.select { |r| r.duration >= threshold }.sort { |l, r| l.duration <=> r.duration }.first(count)

      if res.empty?
        puts format_string({:dark_gray, "No slow tests (threshold: #{threshold.milliseconds}ms)"})
      else
        puts format_string({:blue, "Slowest #{res.size} tests"})
        puts

        res.each do |r|
          name = if r.success?
                   {:green, r.suite, "::", r.test}
                 else
                   {:red, r.suite, "::", r.test}
                 end

          duration_str = "%6d" % r.duration.milliseconds

          puts format_string({:white, duration_str, {:dark_gray, " ms "}, name})
        end
      end

      puts
    end
  end
end
