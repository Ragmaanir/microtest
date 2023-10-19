module Microtest
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
        .select { |r| r.duration >= threshold }
        .sort! { |l, r| r.duration <=> l.duration }
        .first(count)

      if res.empty?
        num, unit = Formatter.format_duration(threshold)
        writeln("No slow tests (threshold: #{num}#{unit})", fg: :dark_gray)
      else
        writeln("Slowest #{res.size} tests", fg: :light_blue)
        br

        res.each do |r|
          symbol, color = result_style(r)

          write(" ")
          write(symbol, fg: color)
          write(Formatter.colorize_duration(r.duration, threshold).to_s)
          write(" ")
          write(r.test.full_name, fg: color)
          br
        end
      end

      br
    end
  end
end
