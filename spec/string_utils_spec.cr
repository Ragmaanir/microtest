require "./spec_helper"

describe Microtest::StringUtils do
  test "diff_index" do
    assert StringUtils.diff_index("", "") == nil
    assert StringUtils.diff_index("a", "a") == nil
    assert StringUtils.diff_index("ax", "ax") == nil

    assert StringUtils.diff_index("a", "x") == 0
    assert StringUtils.diff_index("ax", "xx") == 0
    assert StringUtils.diff_index("aa", "ax") == 1
    assert StringUtils.diff_index("aax", "axa") == 1
  end

  test "split_at" do
    assert StringUtils.split_at("", 0) == {"", "", ""}

    assert StringUtils.split_at("A", 0) == {"", "A", ""}
    assert StringUtils.split_at("A", 1) == {"A", "", ""}
    assert StringUtils.split_at("My String", 3) == {"My ", "S", "tring"}
  end

  test "split_at raises" do
    assert_raises(ArgumentError) do
      StringUtils.split_at("a", -1)
    end

    assert_raises(IndexError) do
      StringUtils.split_at("", 1)
    end

    assert_raises(IndexError) do
      StringUtils.split_at("a", 2)
    end
  end
end
