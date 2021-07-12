defmodule GrowTent.Utils.Units do
  require Logger

  @const_a 17.27
  @const_b 237.3
  @const_c 0.00001525878

  def pascal_to_mbar(pascal) when is_float(pascal) do
    (pascal * 0.01) |> floor()
  end

  def pascal_to_inhg(pascal) when is_float(pascal) do
    (pascal * 0.00029529983071445) |> floor()
  end

  def raw_to_c(raw, offset \\ 4) do
    raw * @const_c - offset
  end

  def celcius_to_f(c) do
    c * 9 / 5 + 32
  end

  def f_to_celcius(f) do
    5 / 9 * (f - 32)
  end

  def dew_point(deg_c, rh) do
    try do
      l = Math.log(rh / 100)
      m = @const_a * deg_c
      n = @const_b + deg_c
      b = (l + m / n) / @const_a
      @const_b * b / (1 - b)
    rescue
      error ->
        _ = Logger.error("DewPoint Calc Error :: #{inspect(error)}")
        dew_point_approximation(deg_c, rh)
    end
  end

  def dew_point_approximation(deg_c, rh) do
    _ = Logger.warn("calculating dew point using approximation")
    deg_c - (100 - rh) / 5
  end
end
