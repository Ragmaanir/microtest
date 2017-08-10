describe MyLib::WaterPump do
  test "that it pumps water" do
    p = MyLib::WaterPump.new("main")
    p.enable
    p.start

    assert(p.pumps_water?)
  end

  test "that it pumps with a certain speed" do
    p = MyLib::WaterPump.new("main", speed: 100)
    p.enable
    p.start

    assert(p.pump_speed > 50)
  end

  test "this one is pending since it got no body"

  test "only run this focused test", :focus do
  end

  test! "and this one too since it is focused also" do
  end
end
