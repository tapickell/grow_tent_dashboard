defmodule GrowTent.Utils.HashRandomTest do
  use GrowTent.DataCase, async: true

  alias GrowTent.Utils.HashRandom

  describe "uniform/3" do
    test "has a uniform distribution" do
      now = ~U(2021-06-20 18:53:00Z)
      id = <<98, 221, 164, 29, 94, 88, 65, 249, 150, 227, 102, 192, 248, 47, 193, 173>>

      frequencies =
        1..10_000
        |> Enum.map(&DateTime.add(now, 60 * &1, :second))
        |> Enum.map(&HashRandom.uniform(id, &1))
        |> Enum.frequencies_by(&trunc(&1 * 10))

      assert frequencies == %{
               0 => 1014,
               1 => 1043,
               2 => 1021,
               3 => 969,
               4 => 989,
               5 => 1001,
               6 => 993,
               7 => 971,
               8 => 1011,
               9 => 988
             }
    end
  end
end
