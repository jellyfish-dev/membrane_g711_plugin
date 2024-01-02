defmodule LUTBuilderTest do
  use ExUnit.Case, async: true

  alias Membrane.G711.LUT.Builder

  test "encoding LUT contains all 16384 entries" do
    lut = Builder.build_linear_to_alaw()

    for i <- 0..16_383 do
      assert Map.has_key?(lut, i)
      assert Map.fetch!(lut, i) in 0..255
    end
  end

  test "decoding LUT contains all 256 entries" do
    lut = Builder.build_alaw_to_linear()

    for i <- 0..255 do
      assert Map.has_key?(lut, i)
      assert Map.fetch!(lut, i) in -32_768..32_767
    end
  end
end
