class WaterPump
  getter name : String
  getter speed : Int32
  getter? enabled : Bool = false

  def initialize(@name, @speed = 10)
  end

  def enable
    @enabled = true
  end
end

describe WaterPump do
  test "enabling" do
    p = WaterPump.new("main")
    p.enable

    assert(p.enabled?)
  end

  test "pump speed" do
    p = WaterPump.new("main", speed: 100)

    assert(p.speed > 50)
  end

  @[Microtest::TestMethod(name: "A test defined using annotations", skip: true)]
  def test_using_annotations
    assert true
  end

  test "this one is pending since it got no body"

  pending "this one is pending even though it has a body" do
    raise "should not raise"
  end
end
