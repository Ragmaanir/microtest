require "json"

require "./formatter"

module Microtest
  module Helper
    alias ResultSymbols = {success: String, failure: String, skip: String}
    alias ResultColors = {success: Symbol, failure: Symbol, skip: Symbol}

    DEFAULT_COLORS = {success: :green, failure: :red, skip: :yellow}

    DOT   = "\u2022"
    TICK  = "\u2713"
    CROSS = "\u2715"

    DOTS  = {success: DOT, failure: DOT, skip: DOT}
    TICKS = {success: TICK, failure: CROSS, skip: TICK}

    def self.result_style(result : TestResult, symbols : ResultSymbols = TICKS, colors : ResultColors = DEFAULT_COLORS)
      {
        symbol: symbols[result.kind],
        color:  colors[result.kind],
      }
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
    @chars : Helper::ResultSymbols

    def initialize(@chars = Helper::DOTS, io = STDOUT)
      super(io)
    end

    def report(result)
      style = Helper.result_style(result, @chars)
      print style[:symbol].colorize(style[:color])
    end

    def finished(ctx : ExecutionContext)
      puts
    end
  end

  class DescriptionReporter < Reporter
    def initialize(io = STDOUT)
      super(io)
    end

    def suite_started(ctx : ExecutionContext, cls : String)
      puts
      puts cls.colorize(:magenta).underline
    end

    def report(result)
      style = Helper.result_style(result, Helper::TICKS)

      symbol = style[:symbol].colorize(style[:color])
      name = result.test.colorize(style[:color])

      puts " #{symbol} #{name}"
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
    @started_at : Time

    def initialize(io = STDOUT)
      super(io)
      @started_at = Time.now
    end

    def report(result : TestResult)
    end

    def started(ctx : ExecutionContext)
      @started_at = Time.now
    end

    def finished(ctx : ExecutionContext)
      ms = (Time.now - @started_at).total_milliseconds
      total = Formatter.format_large_number(ms.to_i)

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
          :duration => res.duration.total_milliseconds,
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
    getter threshold : Time::Span

    COLORS = [:yellow, :red, :light_red, :light_red]

    def initialize(@count = 10, @threshold = Time::Span.new(0, 0, 0, 0, 50), io = STDOUT)
      super(io)
    end

    def report(result : TestResult)
    end

    def finished(ctx : ExecutionContext)
      res = ctx.results
               .select { |r| r.duration >= threshold }
               .sort { |l, r| l.duration <=> r.duration }
               .first(count)

      if res.empty?
        puts "No slow tests (threshold: #{threshold.total_milliseconds}ms)".colorize(:dark_gray)
      else
        puts "Slowest #{res.size} tests".colorize(:blue)
        puts

        res.each do |r|
          style = Helper.result_style(r)

          meth = [r.suite, "::", r.test].join

          duration, unit = Formatter.format_duration(r.duration)

          idx = 3.times.find { |i| threshold * (10**i) > r.duration } || 3
          color = COLORS[idx]

          puts [
            " ",
            style[:symbol].colorize(style[:color]),
            [
              "%6s" % duration,
              " %-2s " % unit,
              meth,
            ].join.colorize(color),
          ].join
        end
      end

      puts
    end
  end
end
