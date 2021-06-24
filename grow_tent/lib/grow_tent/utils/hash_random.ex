defmodule GrowTent.Utils.HashRandom do
  @moduledoc """
  "Random" number generation for deterministic simulation
  """

  @spec uniform(binary(), DateTime.t(), binary()) :: float()
  def uniform(id, timestamp, extra \\ "") do
    <<int_part::integer-size(53), _::bits>> =
      :crypto.hash_init(:sha256)
      |> :crypto.hash_update(id)
      |> :crypto.hash_update(DateTime.to_iso8601(timestamp))
      |> :crypto.hash_update(extra)
      |> :crypto.hash_final()

    int_part * :math.pow(2, -53)
  end
end
