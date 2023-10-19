module Microtest
  class ProgressReporter < TerminalReporter
    @chars : ResultSymbols

    def initialize(@chars = DOTS, io = STDOUT)
      super(io)
    end

    def report(result : TestResult)
      symbol, color = result_style(result, @chars)
      write(symbol, fg: color)
      flush
    end

    def finished(ctx : ExecutionContext)
      br
      br
    end
  end
end
