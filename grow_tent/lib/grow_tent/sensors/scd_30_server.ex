defmodule GrowTent.Sensors.Scd30Server do
  use GenServer

  # Client
  def start_link(params) do
    GenServer.start_link(__MODULE__, params, name: __MODULE__)
  end

  # Server 
  @cmd_continuous_measurement <<0x00, 0x10>>
  @cmd_get_data_ready <<0x02, 0x02>>
  @cmd_read_measurement <<0x03, 0x00>>
  @scd30_default_addr 0x61

  @impl true
  def init(i2c_bus, ambient_pressure = 0, address = @scd30_default_addr) do
    :ok = check_ambient_pressure(ambient_pressure)

    {:ok, i2c_ref} = I2C.open(i2c_bus)

    state = %{
      ref: i2c_ref,
      bus: i2c_bus,
      ambient_pressure: ambient_pressure,
      address: address,
      measurements: %{
        temp_c: nil,
        rh: nil,
        co2_ppm: nil
      }
    }

    {:ok, state, {:continue, :sensor_setup}}
  end

  @impl true
  def handle_continue(
        :sensor_setup,
        %{ref: ref, address: address, ambient_pressure: _ambient_pressure} = state
      ) do
    # do any setup for altitude / barometric pressure / temp offset
    :ok = I2C.write(ref, address, @cmd_get_data_ready)
    {:ok, <<0, 1>>} = I2C.read(ref, address, 2)
    # TODO need to convert ambient to <<0x00, 0x00>> format
    # TODO need to generate crc-8 in <<0x00>>
    :ok = I2C.write(ref, address, @cmd_continuous_measurement <> <<0x00, 0x00>> <> <<0x81>>)

    {:ok, state}
  end

  @impl true
  def handle_cast(:fetch_sensor_data, %{ref: ref, address: address} = state) do
    # read measurement
    :ok = I2C.write(ref, address, <<0x03, 0x00>>)
    {:ok, read_measurement} = I2C.read(ref, address, 19)
    measurements = convert_raw_measurements(read_measurement)
    # send out to pub sub or telemetry
    # send after 60 seconds to fetch fresh data

    {:noreply, %{state | measurements: measurements}}
  end

  defp convert_raw_measurements(read_measurement) do
    <<c02_mmsb::8, c02_mlsb::8, _c02_crc0::8, c02_lmsb::8, c02_llsb::8, _c02_crc1::8, t_mmsb::8,
      t_mlsb::8, _t_crc0::8, t_lmsb::8, t_llsb::8, _t_crc1::8, rh_mmsb::8, rh_mlsb::8,
      _rh_crc0::8, rh_lmsb::8, rh_llsb::8, _::bitstring>> = read_measurement

    <<c02::float-size(32)>> = c02_mmsb <> c02_mlsb <> c02_lmsb <> c02_llsb
    <<t::float-size(32)>> = t_mmsb <> t_mlsb <> t_lmsb <> t_llsb
    <<rh::float-size(32)>> = rh_mmsb <> rh_mlsb <> rh_lmsb <> rh_llsb

    %{c02_ppm: c02, temp_c: t, rh: rh}
  end

  @moduledoc """
  Testing of sensor readings
  # @cmnd_read_measurement needs to be *2 8 bit
  iex(38)> I2C.write(ref, address, <<0x03,0x00>>)
  :ok

  iex(67)> {:ok, reading} = I2C.read(ref, address, 37)                                                              {:ok,                                                                                                                   <<70, 116, 110, 219, 21, 233, 65, 191, 109, 1, 160, 137, 66, 28, 239, 17, 32,                                            157, 0, 0, 129, 0, 0, 129, 73, 14, 212, 22, 78, 151, 74, 126, 1, 209, 72, 53,

  iex(51)>  <<read_header::size(8), c02_mmsb::size(8), c02_mlsb::size(8), co2_crc0::size(8), c02_lmsb::size(8), c02llsb::size(8), co2_crc8::size(8), t_mmsb::size(8), t_mlsb::size(8), t_crc0::size(8), t_lmsb::size(8), t_llsb::size(8), t_crc8::size(8), rh_mmsb::size(8), rh_mlsb::size(8), rh_crc0::size(8), rh_lmsb::size(8), rh_llsb::size(8), rh_crc_8::size(8), rest::bitstring>> = reading
  <<68, 48, 78, 9, 88, 133, 65, 221, 180, 240, 124, 28, 66, 19, 193, 130, 128, 1,
  0, 0, 129, 0, 0, 129, 73, 209, 254, 108, 36, 34, 73, 157, 190, 22, 202, 41,
    0>>

  #normal room levels
  iex(66)> c02_converted = c02_mmsb <<< 24 ||| c02_lmsb <<< 16 ||| c02_lmsb <<< 8 ||| c02llsb
  811096197

  #sprayed duster at sensor
  iex(67)> {:ok, reading_more} = I2C.read(ref, address, 37)                                                              {:ok,                                                                                                                   <<70, 116, 110, 219, 21, 233, 65, 191, 109, 1, 160, 137, 66, 28, 239, 17, 32,                                            157, 0, 0, 129, 0, 0, 129, 73, 14, 212, 22, 78, 151, 74, 126, 1, 209, 72, 53,

  iex(68)>  <<read_header::size(8), c02_mmsb::size(8), c02_mlsb::size(8), co2_crc0::size(8), c02_lmsb::size(8), c02llsb::size(8), co2_crc8::size(8), t_mmsb::size(8), t_mlsb::size(8), t_crc0::size(8), t_lmsb::size(8), t_llsb::size(8), t_crc8::size(8), rh_mmsb::size(8), rh_mlsb::size(8), rh_crc0::size(8), rh_lmsb::size(8), rh_llsb::size(8), rh_crc_8::size(8), rest::bitstring>> = reading_more
  <<70, 116, 110, 219, 21, 233, 65, 191, 109, 1, 160, 137, 66, 28, 239, 17, 32,
    157, 0, 0, 129, 0, 0, 129, 73, 14, 212, 22, 78, 151, 74, 126, 1, 209, 72, 53,
    0>>

  iex(69)> c02_converted = c02_mmsb <<< 24 ||| c02_lmsb <<< 16 ||| c02_lmsb <<< 8 ||| c02llsb                            1947538921                                                                                                             iex(70)> c02_converted * 0.0000001                                                                                     194.7538921

  iex(71)> c02_converted * 0.000001
  1947.5389209999998

  iex(72)> 811096197 * 0.000001
  811.096197
  # in PPM
   bytes_to_float = fn ({mmsb, mlsb, lmsb, llsb}) ->
     converted = mmsb <<< 24 ||| mlsb <<< 16 ||| lmsb <<< 8 ||| llsb
     converted * 0.000001
   end

  <<68, 68, 114, 237, 229, 131, 65, 222, 231, 214, 48, 218, 66, 27, 120, 141, 224,
  35, 0>>
  iex(143)> <<c02::float>> = <<68, 68, 237, 229>>
  ** (MatchError) no match of right hand side value: <<68, 68, 237, 229>>

  iex(143)> <<c02::float-size(32)>> = <<68, 68, 237, 229>>
  <<68, 68, 237, 229>>
  iex(144)> c02
  787.7171020507813
  iex(145)> <<temp::float-size(32)>> = <<65, 222, 214, 48>>     
  <<65, 222, 214, 48>>
  iex(146)> temp
  27.854583740234375
  iex(147)> <<rhumidity::float-size(32)>> = <<66, 27, 141, 224>>      
  <<66, 27, 141, 224>>
  iex(148)> rhumidity
  38.8885498046875

  iex(143)> <<c02::float-size(32)>> = <<68, 68, 237, 229>>
  <<68, 68, 237, 229>>
  iex(144)> c02
  787.7171020507813
  iex(145)> <<temp::float-size(32)>> = <<65, 222, 214, 48>>     
  <<65, 222, 214, 48>>
  iex(146)> temp
  27.854583740234375
  iex(147)> <<rhumidity::float-size(32)>> = <<66, 27, 141, 224>>      
  <<66, 27, 141, 224>>
  iex(148)> rhumidity
  38.8885498046875
  iex(149)> temp * 9/5+ 32
  82.13825073242188
  iex(150)> temp * 1.8 + 32
  82.13825073242188
  iex(151)> <<c02_mmsb, c02_mlsb, c02_lmsb, c02_llsb>>
  <<68, 68, 237, 229>>
  iex(152)> <<c02_reading::float-size(32)>> = <<c02_mmsb, c02_mlsb, c02_lmsb, c02_llsb>>
  <<68, 68, 237, 229>>
  iex(153)> c02_reading
  787.7171020507813

  <<c02_mmsb::8,
    c02_mlsb::8,
    c02_crc0::8,
    c02_lmsb::8,
    c02_llsb::8,
    c02_crc1::8,
    t_mmsb::8,
    t_mlsb::8,
    t_crc0::8,
    t_lmsb::8,
    t_llsb::8,
    t_crc1::8,
    rh_mmsb::8,
    rh_mlsb::8,
    rh_crc0::8,
    rh_lmsb::8,
    rh_llsb::8,
    rh_crc1::8>> = read_measurement

  Python
  >>> from struct import *
  >>> calcsize('>f')
  4
  >>> unpack('>f', b'\x43\xDB\x8C\x2E')[0]
  439.09515380859375
  >>> unpack('>f', b'\x41\xD9\xE7\xFF')[0]
  27.238279342651367
  >>> unpack('>f', b'\x42\x43\x3A\x1B')[0]
  48.80674362182617

  """

  defp check_ambient_pressure(ambient_pressure) do
    if ambient_pressure != 0 &&
         (ambient_pressure < @min_pressure || ambient_pressure > @max_pressure),
       do: throw("ambient_pressure must be from 700-1400 mBar")

    :ok
  end
end
