require "./spec_helper"

describe Microtest::PowerAssert::ListFormatter do
  include Microtest::PowerAssert

  private macro assert_output(exp)
    ListFormatter.new(colorize: false).call(reflect({{exp}}))
  end

  def add(a : Int32, b : Int32)
    a + b
  end

  test! "xxxxxxxxxxx" do
    puts ListFormatter.new.call(reflect([1, 2] == [99]))

    puts ListFormatter.new.call(reflect([1].empty?))
    # puts ListFormatter.new.call(reflect(2 * add(1 + 2 + 3, 5)))
  end

  test! "literal value without comparison" do
    assert assert_output(1) == %[◆ assert 1\n]
    assert assert_output("1") == %[◆ assert "1"\n]
    assert assert_output(:sym) == %[◆ assert :sym\n]
    assert assert_output([] of Int32) == %[◆ assert [] of Int32\n]

    arr = [] of Int32
    assert assert_output(arr) == %[◆ assert arr\n]
  end

  test! "literal value comparison" do
    assert assert_output(1 == 5) == %[◆ assert 1 == 5\n]

    assert assert_output("1" == "5") == %[◆ assert "1" == "5"\n]
  end

  test! "string comparison with literals" do
    assert assert_output("t" + "e" + "s" + "t" == "test") == <<-OUT
    ┏ assert ((("t" + "e") + "s") + "t") == "test"
    ┗ "test" == "test"\n
    OUT
  end

  test! "array literal comparison with expressions" do
    assert assert_output([1 + 5, "str"] == [6, 6]) == <<-OUT
    ┏ assert [1 + 5, "str"] == [6, 6]
    ┗ [6, "str"] == [6, 6]\n
    OUT
  end

  test! "int comparison with function call" do
    assert assert_output(add(1, 1) == 1) == <<-OUT
    ┏ assert (add(1, 1)) == 1
    ┗ 2 == 1\n
    OUT

    assert assert_output(add(1 + 1 + 1, 0*1) == 1) == <<-OUT
    ┏ assert (add((1 + 1) + 1, 0 * 1)) == 1
    ┗ 3 == 1\n
    OUT
  end

  test! "string comparison" do
    assert assert_output("test".upcase == "TEST") == <<-OUT
    ┏ assert "test".upcase == "TEST"
    ┗ "TEST" == "TEST"\n
    OUT
  end

  test! "long string comparison" do
    assert assert_output("abcdefghijkl".upcase == "ABCDEFGHIJKl") == <<-OUT
    ┏ assert "abcdefghijkl".upcase == "ABCDEFGHIJKl"
    ┃ "ABCDEFGHIJKL"
    ┗ "ABCDEFGHIJKl"\n
    OUT
  end

  test! "long string comparison with simplifiable expressions" do
    astr = "a"*6

    assert assert_output((astr + "b" * 6).upcase + "b" == "AAAAAABBBBBBB") == <<-OUT
    ┏ assert ((astr + ("b" * 6)).upcase + "b") == "AAAAAABBBBBBB"
    ┃ "AAAAAABBBBBBb"
    ┗ "AAAAAABBBBBBB"\n
    OUT
  end

  test! "complex expressions" do
    assert assert_output(2 * add(1 + 2 + 3, 5)) == <<-OUT
    ┏ assert 2 * (add((1 + 2) + 3, 5))
    ┃ 2 * 11
    ┗ 22\n
    OUT
  end

  def iszero?(x : Int32)
    x == 0
  end

  test! "call only" do
    assert assert_output(iszero?(50 * 2 - add(99, 2))) == <<-OUT
    ┏ assert iszero?((50 * 2) - (add(99, 2)))
    ┗ iszero?(-1)\n
    OUT
  end

  test "err" do
    raise "exception here"
  end

  test "skipped" do
    skip "pending"
  end
end
