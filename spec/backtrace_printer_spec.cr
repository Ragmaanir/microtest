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

    printer = Microtest::BacktracePrinter.new

    pretty_trace = printer.call(raw_trace, false)

    assert pretty_trace == <<-BACKTRACE
    ┏ CRY: /crystal/main.cr:119 main
    ┃ CRY: /crystal/main.cr:96 main
    ┃ CRY: /crystal/main.cr:110 main_user_code
    ┃ SPEC: spec/spec_helper.cr:64 __crystal_main
    ┃ APP: src/microtest.cr:67 run!
    ┃ APP: src/microtest.cr:71 run!
    ┃ APP: src/microtest.cr:53 run
    ┃ APP: src/microtest.cr:55 run
    ┃ APP: src/microtest/runner.cr:25 call
    ┃ APP: src/microtest/test.cr:36 run_tests
    ┃ CRY: /primitives.cr:255 call
    ┃ SPEC: spec/backtrace_printer_spec.cr:17 ->
    ┃ APP: src/microtest/test.cr:52 run_test
    ┃ CRY: /primitives.cr:255 around_hooks
    ┃ CRY: /primitives.cr:255 ->
    ┃ SPEC: spec/backtrace_printer_spec.cr:17 ->
    ┃ SPEC: spec/backtrace_printer_spec.cr:19 test__prettify_path
    ┗ SPEC: spec/backtrace_printer_spec.cr:5 generate_exception\n
    BACKTRACE
  end

  test "raise when path in backtrace could not be classified" do
    e = generate_exception
    printer = Microtest::BacktracePrinter.new
    printer.call(e.backtrace, raise_on_unmatched_file: true)
  end
end
