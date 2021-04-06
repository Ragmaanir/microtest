require "./formatter"

module Microtest
  module Helper
    alias ResultSymbols = {success: String, failure: String, skip: String}
    alias ResultColors = {success: Symbol, failure: Symbol, skip: Symbol}

    DEFAULT_COLORS = {success: :green, failure: :red, skip: :yellow}

    DOT   = "•" # Bullet "\u2022"
    TICK  = "✓" # Check Mark "\u2713"
    CROSS = "✕" # Multiplication "\u2715"

    DOTS  = {success: DOT, failure: DOT, skip: DOT}
    TICKS = {success: TICK, failure: CROSS, skip: TICK}

    def self.result_style(result : TestResult, symbols : ResultSymbols = TICKS, colors : ResultColors = DEFAULT_COLORS) : Tuple(String, Symbol)
      {
        symbols[result.kind],
        colors[result.kind],
      }
    end

    def self.inspect_unexpected_error(ex : UnexpectedError | HookException) : String
      String.build { |io|
        io << ex.message.colorize(:red)
        io << "\n"

        if ex.exception.backtrace?
          io << BacktracePrinter.new.call(ex.exception.backtrace)
        else
          io << "(no backtrace)"
        end
      }
    end
  end

  class ProgressReporter < Reporter
    @chars : Helper::ResultSymbols

    def initialize(@chars = Helper::DOTS, io = STDOUT)
      super(io)
    end

    def report(result)
      symbol, color = Helper.result_style(result, @chars)
      print symbol.colorize(color)
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
      sym, color = Helper.result_style(result, Helper::TICKS)

      symbol = sym.colorize(color)
      name = result.test.colorize(color)

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

    private def print_error(number : Int32, error : TestFailure)
      ex = error.exception

      puts test_locator_line(number, error.test_method, ex.file, ex.line)

      case ex
      when AssertionFailure
        puts ex.message
      when UnexpectedError
        puts Helper.inspect_unexpected_error(ex)
      else raise "BUG: Invalid Exception"
      end

      puts
    end

    private def test_locator_line(number : Int32, meth : String, file : String, line : Int32) : String
      String.build { |io|
        Colorize.with.red.surround(io) do
          io << ("# %-3d" % (number + 1))
          io << meth
          io << " "
        end
        Colorize.with.dark_gray.surround(io) do
          io << file
          io << ":"
          io << line
        end
      }
    end
  end

  class SummaryReporter < Reporter
    def report(result : TestResult)
    end

    def started(ctx : ExecutionContext)
      @started_at = Time.local
    end

    def finished(ctx : ExecutionContext)
      total, unit = Formatter.format_duration(ctx.duration)

      Termart.io(io, true) { |t|
        if Test.using_focus?
          t.w("USING FOCUS:", bg: :red)
          t.w(" ")
        end

        t.w("Executed #{ctx.executed_tests}/#{ctx.total_tests} tests in #{total}#{unit} with seed #{ctx.random_seed}", fg: :blue)
        t.br

        t.w("Success: ", ctx.total_success, fg: (:green if ctx.total_success > 0))
        t.w(", ")

        t.w("Skips: ", ctx.total_skip, fg: (:yellow if ctx.total_skip > 0))
        t.w(", ")

        t.w("Failures: ", ctx.total_failure, fg: (:red if ctx.total_failure > 0))
        t.br

        if ctx.manually_aborted?
          t.br
          t.l("Test run was aborted manually", fg: :white, bg: :red)
        elsif ex = ctx.aborting_exception
          t.br
          t.l("Test run was aborted by exception in hooks for ", ex.test_method, fg: :white, bg: :red)

          t.l(Helper.inspect_unexpected_error(ex))
        end

        t.br
      }
    end
  end

  class SlowTestsReporter < Reporter
    getter count : Int32
    getter threshold : Time::Span

    def initialize(@count = 3, @threshold = 50.milliseconds, io = STDOUT)
      super(io)
    end

    def report(result : TestResult)
    end

    def finished(ctx : ExecutionContext)
      res = ctx.results
        # ameba:disable Style/VerboseBlock
        .select { |r| r.duration >= threshold }
        .sort! { |l, r| r.duration <=> l.duration }
        .first(count)

      if res.empty?
        num, unit = Formatter.format_duration(threshold)
        puts "No slow tests (threshold: #{num}#{unit})".colorize(:dark_gray)
      else
        puts "Slowest #{res.size} tests".colorize(:blue)
        puts

        res.each do |r|
          symbol, color = Helper.result_style(r)

          meth = [r.suite, "::", r.test].join.colorize(color)

          puts [
            " ",
            symbol.colorize(color),
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
