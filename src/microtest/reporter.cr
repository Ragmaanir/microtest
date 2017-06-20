require "json"

module Microtest
  module Formatter
    # format_large_number(1234567)
    # #=> "1,234,567"
    def self.format_large_number(number, separator : String = ",")
      number.to_s.reverse.gsub(/(\d{3})(?=.)/, "\\1#{separator}").reverse
    end
  end

  abstract class Reporter
    getter io : IO

    def initialize(@io)
    end

    abstract def report(result : TestResult)

    def started(ctx : ExecutionContext)
    end

    def finished(ctx : ExecutionContext)
    end

    def suite_started(ctx : ExecutionContext, cls : String)
    end

    def suite_finished(ctx : ExecutionContext, cls : String)
    end

    private def puts(*args)
      io.puts(*args)
    end
  end

  class ProgressReporter < Reporter
    CHARS = {
      dot:   ["\u2022", "\u2022", "\u2022"],
      ticks: ["\u2713", "\u2715", "\u2715"],
    }

    @chars : Array(String)

    def initialize(@chars = CHARS[:dot], io = STDOUT)
      super(io)
    end

    def report(result)
      case result
      when TestSuccess then print @chars[0].colorize(:green)
      when TestSkip    then print @chars[1].colorize(:yellow)
      when TestFailure then print @chars[2].colorize(:red)
      end
    end

    def finished(ctx : ExecutionContext)
      puts
    end
  end

  class DescriptionReporter < Reporter
    TICK  = "\u2713"
    DOT   = "\u2022"
    CROSS = "\u2715"

    def initialize(io = STDOUT)
      super(io)
    end

    def suite_started(ctx : ExecutionContext, cls : String)
      puts
      puts cls.colorize(:magenta).underline
    end

    def report(result)
      t = result.test
      case result
      when TestSuccess then puts [" ", TICK, " ", t].join.colorize(:green)
      when TestSkip    then puts [" ", DOT, " ", t].join.colorize(:yellow)
      when TestFailure then puts [" ", CROSS, " ", t].join.colorize(:red)
      end
    end

    def finished(ctx : ExecutionContext)
      puts
    end
  end

  class ErrorListReporter < Reporter
    def initialize(io = STDOUT)
      super(io)
    end

    def report(result : TestResult)
    end

    def finished(ctx : ExecutionContext)
      ctx.skips.each do |skip|
        ex = skip.exception
        puts [skip.test_method, " : ", ex.message].join.colorize(:yellow)
        puts
      end

      ctx.errors.each_with_index do |error, i|
        print_error(i, error)
      end
    end

    private def print_error(number, error)
      # puts "|%03d| %s" % {number+1, "-"*25}
      case ex = error.exception
      when AssertionFailure
        puts ["# %-3d" % (number + 1), error.test_method].join.colorize(:red)
        puts ex.message
      when UnexpectedError
        puts ["# %-3d" % (number + 1), error.test_method, " : ", ex.message].join.colorize(:red)
        if ex.exception.backtrace?
          puts ("-" * 60).colorize(:red)
          BacktracePrinter.new.call(ex.exception.backtrace)
        end
      else raise "Invalid Exception"
      end

      puts
    end
  end

  class SummaryReporter < Reporter
    def initialize(io = STDOUT)
      super(io)
    end

    def report(result : TestResult)
    end

    def finished(ctx : ExecutionContext)
      ms = ctx.results.map(&.duration).sum.milliseconds
      total = Formatter.format_large_number(ms)
      puts ["Executed #{ctx.total_tests} tests in #{total} milliseconds with seed #{ctx.random_seed}"].join.colorize(:blue)
      puts [
        ["Success: ", ctx.total_success].join.colorize(:green),
        ", ",
        ["Skips: ", ctx.total_skip].join.colorize(:yellow).toggle(ctx.total_skip > 0),
        ", ",
        ["Failures: ", ctx.total_failure].join.colorize(:red).toggle(ctx.total_failure > 0),
      ].join.colorize(:white)

      puts
    end
  end

  class JsonSummaryReporter < Reporter
    def initialize(io = STDOUT)
      super(io)
    end

    def report(result : TestResult)
    end

    def finished(ctx : ExecutionContext)
      results = ctx.results.reduce({} of String => Hash(String, String)) do |hash, res|
        entry = {
          :suite    => res.suite,
          :test     => res.test,
          :type     => res.class.name,
          :duration => res.duration.milliseconds,
        }

        case res
        when TestFailure, TestSkip then entry = entry.merge({:exception => res.exception.to_s})
        end

        hash.merge({"#{res.suite}##{res.test}" => entry})
      end

      puts(results.to_json)
    end
  end

  class SlowTestsReporter < Reporter
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
        puts "No slow tests (threshold: #{threshold.milliseconds}ms)".colorize(:dark_gray)
      else
        puts "Slowest #{res.size} tests".colorize(:blue)
        puts

        res.each do |r|
          color = case r
                  when TestSuccess then :green
                  when TestFailure then :red
                  when TestSkip    then :yellow
                  else                  :white
                  end

          duration_str = "%6d" % r.duration.milliseconds
          meth = [r.suite, "::", r.test].join

          puts [
            duration_str,
            " ms ".colorize(:dark_gray),
            meth.colorize(color),
          ].join
        end
      end

      puts
    end
  end
end
