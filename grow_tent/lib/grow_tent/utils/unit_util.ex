defmodule GrowTent.Utils.Units do
  def pascal_to_mbar(pascal) when is_float(pascal) do
    (pascal * 0.01) |> floor()
  end

  def pascal_to_inhg(pascal) when is_float(pascal) do
    (pascal * 0.00029529983071445) |> floor()
  end

  def celcius_to_f(c) do
    c * 9 / 5 + 32
  end

  def f_to_celcius(f) do
    5 / 9 * (f - 32)
  end
end
