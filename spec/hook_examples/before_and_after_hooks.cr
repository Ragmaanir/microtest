describe Hooks do
  class Ctx
    property value : Bool = true
  end

  C = Ctx.new

  before do
    C.value = true
  end

  after do
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
