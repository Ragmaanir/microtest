require "./spec_helper"

describe Microtest::BacktracePrinter do
  def generate_exception(msg : String = "the message")
    begin
      raise msg
    rescue e
      return e
    end
  end

  test "is nonempty" do
    e = generate_exception
    printer = Microtest::BacktracePrinter.new

    trace = printer.simplify(e.backtrace)
    assert trace.size > 0
  end
end
