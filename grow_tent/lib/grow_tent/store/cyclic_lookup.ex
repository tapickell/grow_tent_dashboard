defmodule GrowTent.Store.CyclicLookup do
  @moduledoc """
  Efficiently look up a value in a "24-hour" lookup table.

  Uses `:gb_trees` and some index trickery to get `O(log N)` lookup
  """

  @doc """
  Takes a list of {seconds_from_midnight, value} pairs and builds
  a tree for fast lookups.
  """
  def new(data) do
    data
    |> Enum.map(fn {t, v} -> {-t, v} end)
    |> Enum.sort_by(fn {x, _} -> x end)
    |> :gb_trees.from_orddict()
  end

  @doc """
  Given a Datetime, look up the value with the largest
  `seconds_to_midnight` that is before the given value
  """
  def lookup(t, tree) do
    case lookup_tree(t, tree) do
      {key, value, _} ->
        {unwrap(key, t), value}

      :none ->
        # look into when this happens
        raise "UHOH"
    end
  end

  defp get_seconds(t) do
    # NOTE: this is in UTC, need a TZ DB installed
    {seconds, _} = to_seconds_after_midnight(t)

    -seconds
  end

  def lookup_tree(t, tree) do
    get_seconds(t)
    |> :gb_trees.iterator_from(tree)
    |> :gb_trees.next()
  end

  defp unwrap(neg_seconds, t) do
    midnight(t)
    |> DateTime.add(-neg_seconds, :second)
  end

  defp midnight(t) do
    {seconds, microseconds} = to_seconds_after_midnight(t)

    t
    |> DateTime.add(-seconds, :second)
    |> DateTime.add(-microseconds, :microsecond)
  end

  defp to_seconds_after_midnight(t) do
    DateTime.to_time(t)
    |> Time.to_seconds_after_midnight()
  end
end
