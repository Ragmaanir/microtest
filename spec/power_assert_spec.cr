require "./spec_helper"

describe Microtest::PowerAssert do
  include Microtest::PowerAssert

  def constant
    1337
  end

  def function(n : Int32)
    n + 1000
  end

  def yielding(n : Int32, &)
    yield(n + 2000)
  end

  test "reflect_terminal" do
    assert reflect(nil) == TerminalNode.new("nil", nil)
    assert reflect(5) == TerminalNode.new("5", 5)
    assert reflect("str") == TerminalNode.new(%["str"], "str")
    assert reflect(/str/) == TerminalNode.new(%[/str/], /str/)
    assert reflect(1..5) == TerminalNode.new(%[1..5], 1..5)
    assert reflect("1".."5") == TerminalNode.new(%["1".."5"], "1".."5")

    # ameba:disable Lint/UselessAssign
    assert reflect(b = 0) == TerminalNode.new(%[b = 0], 0)

    a = 1
    assert reflect(a) == TerminalNode.new("a", 1)

    assert reflect(constant) == CallNode.new(
      %[constant],
      %[constant],
      1337,
      EmptyNode.new,
      [] of Node,
      [] of NamedArgNode
    )

    assert reflect(function(1)) == CallNode.new(
      %[function],
      %[function(1)],
      1001,
      EmptyNode.new,
      [TerminalNode.new("1", 1)] of Node,
      [] of NamedArgNode
    )

    assert reflect(yielding(1) { |x| x }) == CallNode.new(
      %[yielding],
      %[yielding(1) do |x|\n  x\nend],
      2001,
      EmptyNode.new,
      [TerminalNode.new("1", 1)] of Node,
      [] of NamedArgNode
    )
  end

  def append(a : Array(Int32))
    a << 1
    a
  end

  test "assert evaluates expressions only once" do
    arr = [] of Int32

    begin
      assert(append(append(append(arr))) == 0)
    rescue AssertionFailure
    end

    assert arr.size == 3
  end
end
