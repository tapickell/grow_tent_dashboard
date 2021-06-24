defmodule GrowTent.Store.CyclicLookupTest do
  use GrowTent.DataCase, async: true

  alias GrowTent.Store.CyclicLookup

  describe "new" do
    test "returns a gb_tree" do
      tree = CyclicLookup.new([{0, "value 1"}, {1, "value 2"}])

      refute :gb_trees.is_empty(tree)
    end
  end

  describe "lookup" do
    setup do
      {:ok, tree: CyclicLookup.new([{0, "value 1"}, {10, "value 2"}, {3642, "value 3"}])}
    end

    test "looks up a value at midnight", context do
      t = ~U(2021-06-20 00:00:00.000000Z)

      {result_t, result_v} = CyclicLookup.lookup(t, context.tree)

      assert result_t == t
      assert result_v == "value 1"
    end

    test "looks up a value in the first period", context do
      t = ~U(2021-06-20 00:00:04.045000Z)

      {result_t, result_v} = CyclicLookup.lookup(t, context.tree)

      assert result_t == ~U(2021-06-20 00:00:00.000000Z)
      assert result_v == "value 1"
    end

    test "looks up a value in the last period", context do
      t = ~U(2021-06-20 08:00:04.045000Z)

      {result_t, result_v} = CyclicLookup.lookup(t, context.tree)

      assert result_t == ~U(2021-06-20 01:00:42.000000Z)
      assert result_v == "value 3"
    end
  end
end
