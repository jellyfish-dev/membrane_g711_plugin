defmodule Membrane.G711.LUTBuilder do
  @moduledoc false

  import Bitwise

  @alaw_mask_1 0x55
  @alaw_mask_2 0xD5
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
    {_j, table} =
      Enum.reduce(0..127, {0, %{}}, fn i, {j, table} ->
        v =
          if i != 127 do
            v1 = alaw_to_linear(bxor(i, @alaw_mask_2))
            v2 = alaw_to_linear(bxor(i + 1, @alaw_mask_2))

            (v1 + v2 + 4) >>> 3
          else
            8192
          end

        fill_table(table, i, j, v)
      end)

    Map.put(table, 0, table[1])
  end

  defp alaw_to_linear(uint8) do
    alaw_value = bxor(uint8, @alaw_mask_1)
    t = alaw_value &&& @quant_mask
    seg = (alaw_value &&& @seg_mask) >>> @seg_shift

    t =
      if seg != 0 do
        (t + t + 1 + 32) <<< (seg + 2)
      else
        (t + t + 1) <<< 3
      end

    if (alaw_value &&& @sign_bit) != 0, do: t, else: -t
  end

  defp fill_table(table, i, j, v) do
    if j >= v do
      {j, table}
    else
      table = Map.put(table, 8192 + j, bxor(i, @alaw_mask_2))

      table =
        if j > 0 do
          Map.put(table, 8192 - j, bxor(i, @alaw_mask_1))
        else
          table
        end

      fill_table(table, i, j + 1, v)
    end
  end
end
