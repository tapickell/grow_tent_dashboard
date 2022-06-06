defmodule GrowTent.Sensors.Tsl2951Test do
  use GrowTent.DataCase, async: true

  alias GrowTent.Sensors.Tsl2951

  describe "lux calcuation" do
    test "lux with positive numbers" do
      {chan_zero, chan_one} = {34_000, 24_000}
      assert 118.81188118811879 == Tsl2951.lux({chan_zero, chan_one})
    end

    test "lux with zero on chan_zero" do
      {chan_zero, chan_one} = {0, -24_000}
      assert 0 == Tsl2951.lux({chan_zero, chan_one})
    end

    test "lux with gt max_counts" do
      max_counts = 36863
      assert 0 == Tsl2951.lux({max_counts, max_counts})
    end
  end
end
