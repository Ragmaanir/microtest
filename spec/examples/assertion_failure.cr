describe AssertionFailure do
  test "assertion failure" do
    a = 5
    b = "aaaaaa"
    assert "a" * a == b
  end
end
