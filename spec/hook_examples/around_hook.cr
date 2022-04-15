describe AroundHook do
  class Ctx
    property value : Bool = true
  end

  C = Ctx.new

  around do |block|
    C.value = true
    block.call
    assert C.value == false
  end

  test "first" do
    assert C.value == true
    C.value = false
  end

  test "second" do
    assert C.value == true
    C.value = false
  end
end
