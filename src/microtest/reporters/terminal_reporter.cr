module Microtest
  abstract class TerminalReporter < Reporter
    alias ResultSymbols = {success: String, failure: String, skip: String, abortion: String}
    alias ResultColors = {success: Symbol, failure: Symbol, skip: Symbol, abortion: Symbol}

    DEFAULT_COLORS = {success: :green, failure: :red, skip: :yellow, abortion: :yellow}

    DOT   = "•" # Bullet "\u2022"
    TICK  = "✓" # Check Mark "\u2713"
    CROSS = "✕" # Multiplication "\u2715"
    SKULL = "💀"
    BANG  = "💥"

    DOTS  = {success: DOT, failure: DOT, skip: DOT, abortion: BANG}
    TICKS = {success: TICK, failure: CROSS, skip: TICK, abortion: BANG}

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

    private def exception_to_string(ex : Exception, highlight : String? = nil) : String
      String.build { |io|
        io << ex.message.colorize(:red)
        io << "\n"

        if b = ex.backtrace?
          io << BacktracePrinter.new.call(b, highlight)
        else
          io << "(no backtrace)"
        end
      }
    end
  end
end
