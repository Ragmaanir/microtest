module Microtest
  class ErrorListReporter < TerminalReporter
    def report(result : TestResult)
    end

    def finished(ctx : ExecutionContext)
      ctx.skips.each do |skip|
        ex = skip.exception

        write(skip.test.sanitized_name, ": ", ex.message, fg: YELLOW)
        write(" in ", BacktracePrinter.simplify_path(ex.file)[1], ":", ex.line, fg: DARK_GRAY)
        br
      end

      br if !ctx.skips.empty?

      ctx.failures.each_with_index do |failure, i|
        print_failure(i, failure)
      end

      if a = ctx.abortion_info
        br
        writeln(exception_to_string(a.exception))
      end
    end

    private def print_failure(number : Int32, failure : TestFailure)
      ex = failure.exception
      test = failure.test
      bold = Colorize::Mode::Bold

      write("# %-3d" % (number + 1), test.full_name, " ", fg: RED, m: bold)

      case ex
      when AssertionFailure
        path = BacktracePrinter.simplify_path(ex.file)[1]
        write(path, ":", ex.line, fg: LIGHT_GRAY, m: bold)
        br
        writeln(ex.message)
      when UnexpectedError
        path = BacktracePrinter.simplify_path(test.filename)[1]
        write(path, ":", test.line_number, fg: LIGHT_GRAY, m: bold)
        br
        writeln(exception_to_string(ex.exception, test.method_name))
      else Microtest.bug("Invalid Exception")
      end

      br
    end
  end
end
