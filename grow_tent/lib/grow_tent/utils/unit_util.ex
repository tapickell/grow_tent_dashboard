defmodule GrowTent.Utils.Units do
  def pascal_to_mbar(pascal) when is_float(pascal) do
    (pascal * 0.01) |> floor()
  end

  def pascal_to_inhg(pascal) when is_float(pascal) do
    (pascal * 0.00029529983071445) |> floor()
  end
end
