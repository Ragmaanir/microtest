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

    def initialize(@io = STDOUT)
    end

    abstract def report(result : TestResult)

    def abort(ctx : ExecutionContext, exception : HookException)
    end

    def started(ctx : ExecutionContext)
    end

    def finished(ctx : ExecutionContext)
    end

    def suite_started(ctx : ExecutionContext, cls : String)
    end

    def suite_finished(ctx : ExecutionContext, cls : String)
    end

    private def print(*args)
      io.print(*args)
      io.flush
    end

    private def puts(*args)
      io.puts(*args)
      io.flush
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
      puts
    end
  end

  class DescriptionReporter < Reporter
    getter threshold : Time::Span

    def initialize(@threshold = 50.milliseconds, io = STDOUT)
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

      time_text = Formatter.colorize_duration(result.duration, threshold)
      puts [" ", symbol, time_text.colorize(:dark_gray), " ", name].join
    end

    def finished(ctx : ExecutionContext)
      puts
    end
  end

  class ErrorListReporter < Reporter
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
      case ex = error.exception
      when AssertionFailure
        print_assertion_failure(number, error, ex)
      when UnexpectedError
        print_unexpected_error(number, error, ex)
      else raise "Invalid Exception"
      end

      puts
    end

    private def print_unexpected_error(number, error, ex : UnexpectedError)
      puts ["# %-3d" % (number + 1), error.test_method].join.colorize(:red)
      puts ex.message.colorize(:red)

      if ex.exception.backtrace?
        puts ("-" * 60).colorize(:red)
        puts BacktracePrinter.new.call(ex.exception.backtrace)
      else
        puts "(no backtrace)"
      end
    end

    private def print_assertion_failure(number, error, ex : AssertionFailure)
      puts ["# %-3d" % (number + 1), error.test_method, " ", ex.file, ":", ex.line].join.colorize(:red)
      puts ex.message
    end
  end

  class SummaryReporter < Reporter
    def report(result : TestResult)
    end

    def started(ctx : ExecutionContext)
      @started_at = Time.now
    end

    def finished(ctx : ExecutionContext)
      total, unit = Formatter.format_duration(ctx.duration)

      focus_hint = "USING FOCUS: " if Test.using_focus?
      puts [focus_hint.colorize.back(:red), "Executed #{ctx.total_tests} tests in #{total}#{unit} with seed #{ctx.random_seed}".colorize(:blue)].join
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
        aborting_exception: ctx.aborting_exception.try(&.message),
        total_count:        ctx.total_tests,
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

  class SlowTestsReporter < Reporter
    getter count : Int32
    getter threshold : Time::Span

    def initialize(@count = 10, @threshold = 50.milliseconds, io = STDOUT)
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
        num, unit = Formatter.format_duration(threshold)
        puts "No slow tests (threshold: #{num}#{unit})".colorize(:dark_gray)
      else
        puts "Slowest #{res.size} tests".colorize(:blue)
        puts

        res.each do |r|
          style = Helper.result_style(r)

          meth = [r.suite, "::", r.test].join.colorize(style[:color])

          puts [
            " ",
            style[:symbol].colorize(style[:color]),
            Formatter.colorize_duration(r.duration, threshold),
            " ",
            meth,
          ].join
        end
      end

      puts
    end
  end
end
