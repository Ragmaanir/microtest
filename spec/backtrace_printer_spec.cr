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

  test "raise when path in backtrace could not be classified" do
    e = generate_exception
    printer = Microtest::BacktracePrinter.new
    printer.call(e.backtrace, true)
  end
end
