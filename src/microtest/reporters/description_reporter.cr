module Microtest
  class DescriptionReporter < TerminalReporter
    getter threshold : Time::Span

    def initialize(@threshold = 50.milliseconds, io = STDOUT)
      super(io)
    end

    def suite_started(ctx : ExecutionContext, cls : String)
      br
      writeln(cls, fg: MAGENTA, m: Colorize::Mode::Underline)
    end

    def report(result : TestResult)
      symbol, color = result_style(result, TICKS)

      time_text = Formatter.colorize_duration(result.duration, threshold)

      write(" ")
      write(symbol, fg: color)
      write(time_text.to_s)
      write(" ")
      write(result.test.name, fg: color)
      br
    end

    def finished(ctx : ExecutionContext)
      br
    end
  end
end
