describe First do
  test "success" do
  end

  test "skip this"
end

describe Second do
  def raise_an_error
    raise "Oh, this is wrong"
  end

  test "first failure" do
    a = 5
    b = 7
    assert a == b * 2
  end

  test "error" do
    raise_an_error
  end
end
