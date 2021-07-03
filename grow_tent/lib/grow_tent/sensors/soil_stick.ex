defmodule GrowTent.Sensors.SoilStick do
  require Logger

  @default_address 0x19

  def start_link(bus_name, address \\ @default_address) do
    I2cServer.start_link(bus_name: bus_name, bus_address: address)
  end

  def init(stick) do
    :ok
  end

  def measure(stick) do
    %{}
  end

  def transform(measurements) do
    measurements
  end
end
