defmodule Membrane.G711.LUTBuilder do
  @moduledoc false

  import Bitwise

  @complement_mask 0x55
  @alaw_mask 0xD5
  @quant_mask 0xF
  @seg_shift 4
  @sign_bit 0x80
  @seg_mask 0x70

  @spec build_alaw_to_linear() :: %{(0..255) => 0..65_535}
  def build_alaw_to_linear() do
    Map.new(0..255, fn i -> {i, alaw_to_linear(i)} end)
  end

  @spec build_linear_to_alaw() :: %{(0..16_383) => 0..255}
  def build_linear_to_alaw() do
    j = 1
    table = %{8192 => @alaw_mask}

    {j, table} =
      Enum.reduce(0..126, {j, table}, fn i, {j, table} ->
        v1 = i |> bxor(@alaw_mask) |> alaw_to_linear()
        v2 = (i + 1) |> bxor(@alaw_mask) |> alaw_to_linear()
        v = (v1 + v2 + 4) |> bsr(3)

        fill_table(table, i, j, v)
      end)

    table =
      Enum.reduce(j..8191, table, fn j, table ->
        table
        |> Map.put(8192 - j, bxor(127, @complement_mask))
        |> Map.put(8192 + j, bxor(127, @alaw_mask))
      end)

    Map.put(table, 0, table[1])
  end

  defp alaw_to_linear(uint8) do
    alaw_value = bxor(uint8, @complement_mask)
    t = band(alaw_value, @quant_mask)
    seg = alaw_value |> band(@seg_mask) |> bsr(@seg_shift)

    t =
      if seg != 0 do
        (t + t + 1 + 32) |> bsl(seg + 2)
      else
        (t + t + 1) |> bsl(3)
      end

    if band(alaw_value, @sign_bit) != 0, do: t, else: -t
  end

  defp fill_table(table, _i, j, v) when j >= v do
    {j, table}
  end

  defp fill_table(table, i, j, v) do
    table
    |> Map.put(8192 - j, bxor(i, @complement_mask))
    |> Map.put(8192 + j, bxor(i, @alaw_mask))
    |> fill_table(i, j + 1, v)
  end
end
