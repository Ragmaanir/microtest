require "./spec_helper"

describe Microtest::BacktracePrinter do
  def generate_exception(msg : String = "the message")
    raise msg
  rescue e
    e
  end

  test "is nonempty" do
    e = generate_exception
    printer = Microtest::BacktracePrinter.new

    trace = printer.simplify(e.backtrace)
    assert trace.size > 0
  end

  test "prettify path" do
    raw_trace = <<-BACKTRACE.split("\n")
    spec/backtrace_printer_spec.cr:5:5 in 'generate_exception'
    spec/backtrace_printer_spec.cr:19:5 in 'test__prettify_path'
    spec/backtrace_printer_spec.cr:17:1 in '->'
    #{CRYSTAL_DIR}/primitives.cr:255:3 in '->'
    #{CRYSTAL_DIR}/primitives.cr:255:3 in 'around_hooks'
    src/microtest/test.cr:52:9 in 'run_test'
    spec/backtrace_printer_spec.cr:17:1 in '->'
    #{CRYSTAL_DIR}/primitives.cr:255:3 in 'call'
    src/microtest/test.cr:36:13 in 'run_tests'
    src/microtest/runner.cr:25:9 in 'call'
    src/microtest.cr:55:5 in 'run'
    src/microtest.cr:53:3 in 'run'
    src/microtest.cr:71:5 in 'run!'
    src/microtest.cr:67:5 in 'run!'
    spec/spec_helper.cr:64:1 in '__crystal_main'
    #{CRYSTAL_DIR}/crystal/main.cr:110:5 in 'main_user_code'
    #{CRYSTAL_DIR}/crystal/main.cr:96:7 in 'main'
    #{CRYSTAL_DIR}/crystal/main.cr:119:3 in 'main'
    __libc_start_main
    _start
    ???
    BACKTRACE

    # backtraces on MSVC do not have column numbers
    {% if flag?(:msvc) %}
      raw_trace.map! &.sub(/:\d+ in/, " in")
    {% end %}

    printer = Microtest::BacktracePrinter.new

    pretty_trace = printer.call(raw_trace, colorize: false)

    s = Path::SEPARATORS[0]

    assert pretty_trace == <<-BACKTRACE
    ┏ CRY: #{s}crystal#{s}main.cr:119 main
    ┃ CRY: #{s}crystal#{s}main.cr:96 main
    ┃ CRY: #{s}crystal#{s}main.cr:110 main_user_code
    ┃ SPEC: spec#{s}spec_helper.cr:64 __crystal_main
    ┃ APP: src#{s}microtest.cr:67 run!
    ┃ APP: src#{s}microtest.cr:71 run!
    ┃ APP: src#{s}microtest.cr:53 run
    ┃ APP: src#{s}microtest.cr:55 run
    ┃ APP: src#{s}microtest#{s}runner.cr:25 call
    ┃ APP: src#{s}microtest#{s}test.cr:36 run_tests
    ┃ CRY: #{s}primitives.cr:255 call
    ┃ SPEC: spec#{s}backtrace_printer_spec.cr:17 ->
    ┃ APP: src#{s}microtest#{s}test.cr:52 run_test
    ┃ CRY: #{s}primitives.cr:255 around_hooks
    ┃ CRY: #{s}primitives.cr:255 ->
    ┃ SPEC: spec#{s}backtrace_printer_spec.cr:17 ->
    ┃ SPEC: spec#{s}backtrace_printer_spec.cr:19 test__prettify_path
    ┗ SPEC: spec#{s}backtrace_printer_spec.cr:5 generate_exception\n
    BACKTRACE
  end

  test "raise when path in backtrace could not be classified" do
    e = generate_exception
    printer = Microtest::BacktracePrinter.new
    printer.call(e.backtrace, colorize: false)
  end
end
