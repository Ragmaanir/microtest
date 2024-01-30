require "./spec_helper"

describe Microtest::Termart do
  def grouped_lines(*args, colorize = false)
    String.build { |io|
      t = Termart.new(io, colorize)
      t.grouped_lines(*args)
    }
  end

  test "grouped_lines without color" do
    res = grouped_lines(["A: aaa"], RED)

    assert res == %{◆ A: aaa\n}

    res = grouped_lines(["A: aaa", "B: bbb", "C: ccc"], WHITE)

    assert res == <<-STR
    ┏ A: aaa
    ┃ B: bbb
    ┗ C: ccc\n
    STR
  end

  test "grouped_lines with color" do
    res = grouped_lines(["A: aaa"], RED, colorize: true)

    assert res == %{\e[38;2;220;0;0m◆\e[0m A: aaa\n}

    res = grouped_lines(["A: aaa", "B: bbb", "C: ccc"], RED, colorize: true)

    assert res == <<-STR
    \e[38;2;220;0;0m┏\e[0m A: aaa
    \e[38;2;220;0;0m┃\e[0m B: bbb
    \e[38;2;220;0;0m┗\e[0m C: ccc\n
    STR
  end
end
