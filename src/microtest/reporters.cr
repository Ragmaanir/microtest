require "./formatter"

module Microtest
  abstract class TerminalReporter < Reporter
    alias ResultSymbols = {success: String, failure: String, skip: String}
    alias ResultColors = {success: Symbol, failure: Symbol, skip: Symbol}

    DEFAULT_COLORS = {success: :green, failure: :red, skip: :yellow}

    DOT   = "•" # Bullet "\u2022"
    TICK  = "✓" # Check Mark "\u2713"
    CROSS = "✕" # Multiplication "\u2715"

    DOTS  = {success: DOT, failure: DOT, skip: DOT}
    TICKS = {success: TICK, failure: CROSS, skip: TICK}

    private getter t : Termart

    def initialize(io : IO = STDOUT)
      super
      @t = Termart.new(io, true)
    end

    private def write(*args, **opts)
      t.w(*args, **opts)
    end

    private def writeln(*args, **opts)
      t.l(*args, **opts)
    end

    private def br
      t.br
    end

    private def flush
      t.flush
    end

    private def result_style(
      result : TestResult,
      symbols : ResultSymbols = TICKS,
      colors : ResultColors = DEFAULT_COLORS
    ) : Tuple(String, Symbol)
      {
        symbols[result.kind],
        colors[result.kind],
      }
    end

    private def inspect_unexpected_error(ex : UnexpectedError | HookException) : String
      String.build { |io|
        io << ex.message.colorize(:red)
        io << "\n"

        if ex.exception.backtrace?
          io << BacktracePrinter.new.call(ex.exception.backtrace, true, false)
        else
          io << "(no backtrace)"
        end
      }
    end
  end

  class ProgressReporter < TerminalReporter
    @chars : ResultSymbols

    def initialize(@chars = DOTS, io = STDOUT)
      super(io)
    end

    def report(result)
      symbol, color = result_style(result, @chars)
      write(symbol, fg: color)
      flush
    end

    def finished(ctx : ExecutionContext)
      br
      br
    end
  end

  class DescriptionReporter < TerminalReporter
    getter threshold : Time::Span

    def initialize(@threshold = 50.milliseconds, io = STDOUT)
      super(io)
    end

    def suite_started(ctx : ExecutionContext, cls : String)
      br
      writeln(cls, fg: :magenta, m: :underline)
    end

    def report(result)
      symbol, color = result_style(result, TICKS)

      time_text = Formatter.colorize_duration(result.duration, threshold)

      write(" ")
      write(symbol, fg: color)
      write(time_text.to_s)
      write(" ")
      write(result.test, fg: color)
      br
    end

    def finished(ctx : ExecutionContext)
      br
    end
  end

  class ErrorListReporter < TerminalReporter
    def report(result : TestResult)
    end

    def finished(ctx : ExecutionContext)
      ctx.skips.each do |skip|
        ex = skip.exception

        write(skip.test_method, ": ", ex.message, fg: :yellow)
        write(" in ", BacktracePrinter.simplify_path(ex.file)[1], ":", ex.line, fg: :dark_gray)
        br
      end

      br if !ctx.skips.empty?

      ctx.errors.each_with_index do |error, i|
        print_error(i, error)
      end
    end

    private def print_error(number : Int32, error : TestFailure)
      ex = error.exception

      write("# %-3d" % (number + 1), error.test_method, " ", fg: :red)

      case ex
      when AssertionFailure
        write(BacktracePrinter.simplify_path(ex.file)[1], ":", ex.line, fg: :dark_gray)
        br
        writeln(ex.message)
      when UnexpectedError
        br
        writeln(inspect_unexpected_error(ex))
      else Microtest.bug("Invalid Exception")
      end

      br
    end
  end

  class SummaryReporter < TerminalReporter
    def report(result : TestResult)
    end

    def started(ctx : ExecutionContext)
      @started_at = Time.local
    end

    def finished(ctx : ExecutionContext)
      total, unit = Formatter.format_duration(ctx.duration)

      if Test.using_focus?
        write("USING FOCUS:", bg: :red)
        write(" ")
      end

      write("Executed #{ctx.executed_tests}/#{ctx.total_tests} tests in #{total}#{unit} with seed #{ctx.random_seed}", fg: :blue)
      br

      write("Success: ", ctx.total_success, fg: (:green if ctx.total_success > 0))
      write(", ")

      write("Skips: ", ctx.total_skip, fg: (:yellow if ctx.total_skip > 0))
      write(", ")

      write("Failures: ", ctx.total_failure, fg: (:red if ctx.total_failure > 0))
      br

      if ctx.manually_aborted?
        br
        writeln("Test run was aborted manually", fg: :white, bg: :red)
      elsif ex = ctx.aborting_exception
        br
        writeln("Test run was aborted by exception in hooks for ", ex.test_method, fg: :white, bg: :red)

        writeln(inspect_unexpected_error(ex))
      end

      br
    end
  end

  class SlowTestsReporter < TerminalReporter
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
        writeln("No slow tests (threshold: #{num}#{unit})", fg: :dark_gray)
      else
        writeln("Slowest #{res.size} tests", fg: :blue)
        br

        res.each do |r|
          symbol, color = result_style(r)

          write(" ")
          write(symbol, fg: color)
          write(Formatter.colorize_duration(r.duration, threshold).to_s)
          write(" ")
          write(r.suite, "::", r.test, fg: color)
          br
        end
      end

      br
    end
  end
end
