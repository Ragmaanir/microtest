require "./spec_helper"

describe Microtest::PowerAssert::ListFormatter do
  include Microtest::PowerAssert

  private def format_ast(ast)
    ListFormatter.new(colorize: false).call(ast)
  end

  private macro assert_out(expression, expected)
    assert format_ast(reflect({{expression}})) == {{expected}}
  end

  private def add(a : Int32, b : Int32)
    a + b
  end

  private def iszero?(x : Int32)
    x == 0
  end

  test! "literal value without comparison" do
    assert_out(1, %[◆ assert 1\n])
    assert_out("1", %[◆ assert "1"\n])
    assert_out(:sym, %[◆ assert :sym\n])
    assert_out([1, 2], %[◆ assert [1, 2]\n])

    arr = [] of Int32
    assert_out(arr, %[┏ assert arr\n┗ []\n])
    assert_out([] of Int32, %[◆ assert [] of Int32\n])
  end

  test! "literal value comparison" do
    assert_out(1 == 5, %[◆ assert 1 == 5\n])
    assert_out("1" == "5", %[◆ assert "1" == "5"\n])
  end

  test! "string comparison with expressions" do
    assert_out(
      "t" + "e" + "s" + "t" == "test",
      <<-OUT
      ┏ assert ((("t" + "e") + "s") + "t") == "test"
      ┗ "test" == "test"\n
      OUT
    )
  end

  test! "array literal comparison with expressions" do
    assert_out(
      [1 + 5, "str"] == [6, 6],
      <<-OUT
      ┏ assert [1 + 5, "str"] == [6, 6]
      ┗ [6, "str"] == [6, 6]\n
      OUT
    )
  end

  test! "int comparison with function call" do
    assert_out(
      add(1, 1) == 1,
      <<-OUT
      ┏ assert (add(1, 1)) == 1
      ┗ 2 == 1\n
      OUT
    )

    # FIXME add(3, 0) == 1
    assert_out(
      add(1 + 1 + 1, 0*1) == 1,
      <<-OUT
      ┏ assert (add((1 + 1) + 1, 0 * 1)) == 1
      ┗ 3 == 1\n
      OUT
    )
  end

  test! "string comparison" do
    assert_out(
      "test".upcase == "TEST",
      <<-OUT
      ┏ assert "test".upcase == "TEST"
      ┗ "TEST" == "TEST"\n
      OUT
    )
  end

  test! "long string comparison" do
    assert_out(
      "abcdefghijkl".upcase == "ABCDEFGHIJKl",
      <<-OUT
      ┏ assert "abcdefghijkl".upcase == "ABCDEFGHIJKl"
      ┃ "ABCDEFGHIJKL"
      ┗ "ABCDEFGHIJKl"\n
      OUT
    )
  end

  test! "long string comparison with simplifiable expressions" do
    astr = "a"*6

    assert_out(
      (astr + "b" * 6).upcase + "b" == "AAAAAABBBBBBB",
      <<-OUT
      ┏ assert ((astr + ("b" * 6)).upcase + "b") == "AAAAAABBBBBBB"
      ┃ "AAAAAABBBBBBb"
      ┗ "AAAAAABBBBBBB"\n
      OUT
    )
  end

  test! "complex expressions" do
    assert_out(
      2 * add(1 + 2 + 3, 5),
      <<-OUT
      ┏ assert 2 * (add((1 + 2) + 3, 5))
      ┃ 2 * 11
      ┗ 22\n
      OUT
    )
  end

  test! "call only" do
    assert_out(
      iszero?(50 * 2 - add(99, 2)),
      <<-OUT
      ┏ assert iszero?((50 * 2) - (add(99, 2)))
      ┗ iszero?(-1)\n
      OUT
    )

    assert_out([1].empty?, %[◆ assert [1].empty?\n])
  end

  test "err" do
    raise "exception here"
  end

  test "skipped" do
    skip "pending"
  end
end
