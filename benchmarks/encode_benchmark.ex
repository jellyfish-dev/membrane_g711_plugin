defmodule Membrane.G711.Benchmark.Encode do
  @moduledoc false

  import Bitwise

  alias Membrane.G711.FFmpeg.Encoder
  alias Membrane.G711.LUT

  defmacro to_lut_key(sample) do
    quote do
      (unquote(sample) + 32_768) |> bsr(2)
    end
  end

  @lut LUT.Builder.build_linear_to_alaw()

  for {k, v} <- @lut do
    defp do_encode_pmf(unquote(k)), do: unquote(v)
  end

  def inputs() do
    {:ok, payload} = File.read("test/fixtures/encode/input-s16le.raw")

    <<payload_small::binary-size(320), payload_medium::binary-size(2048),
      payload_big::binary-size(40_960), _rest::binary>> = payload

    %{
      "Small 320 B (encoded into 160 B, typical RTP payload size)" => payload_small,
      "Medium 2048 B" => payload_medium,
      "Big 40960 B" => payload_big
    }
  end

  def runs() do
    {:ok, encoder_ref} = Encoder.Native.create(:s16le)
    lut = LUT.Builder.build_linear_to_alaw()

    %{
      "FFmpeg NIFs" => fn payload -> benchmark_nif(payload, encoder_ref) end,
      "Map LUT in state" => fn payload -> benchmark_state(payload, lut) end,
      "Module attribute map LUT" => fn payload -> benchmark_mattr(payload) end,
      "Pattern match function LUT" => fn payload -> benchmark_pmf(payload) end
    }
  end

  defp benchmark_nif(payload, encoder_ref) do
    {:ok, [frame]} = Encoder.Native.encode(payload, encoder_ref)
    frame
  end

  defp benchmark_state(payload, lut) do
    for <<sample::integer-signed-little-16 <- payload>>, into: <<>> do
      <<lut[sample |> to_lut_key()]>>
    end
  end

  defp benchmark_mattr(payload) do
    for <<sample::integer-signed-little-16 <- payload>>, into: <<>> do
      <<@lut[sample |> to_lut_key()]>>
    end
  end

  defp benchmark_pmf(payload) do
    for <<sample::integer-signed-little-16 <- payload>>, into: <<>> do
      <<sample |> to_lut_key() |> do_encode_pmf()>>
    end
  end
end
