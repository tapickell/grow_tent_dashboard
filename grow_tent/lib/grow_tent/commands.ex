defmodule GrowTent.Commands do
  @matcher ["interface", "wlan0", "addresses"]

  def firmware do
    device_name = GrowTentWeb.Telemetry.device_name()
    sensors = sensors()
    target = target()
    "MIX_TARGET=#{target} DEVICE_NAME=#{device_name} SENSORS='#{sensors}' mix firmware"
  end

  def upload do
    ip_address = ipv4_address()
    target = target()
    "./upload.sh #{ip_address} _build/#{target}_dev/nerves/images/grow_tent_firmware.fw  "
  end

  defp ipv4_address do
    [{_matcher, addresses}] = VintageNet.get_by_prefix(@matcher)
    [ipv4] = Enum.filter(addresses, &(&1.family == :inet))
    VintageNet.IP.ip_to_string(ipv4.address)
  end

  defp sensors do
    GrowTent.Sensors.Control.sensors()
    |> Enum.intersperse(",")
    |> List.to_string()
  end

  defp target do
    Application.get_all_env(:grow_tent_firmware)[:target]
    |> Atom.to_string()
  end
end
