defmodule Membrane.G711.Benchmark.Decode do
  @moduledoc false

  alias Membrane.G711.FFmpeg.Decoder
  alias Membrane.G711.LUT

  @lut LUT.Builder.build_alaw_to_linear()

  for {k, v} <- @lut do
    defp do_decode_pmf(unquote(k)), do: unquote(v)
  end

  def inputs() do
    {:ok, payload} = File.read("test/fixtures/decode/input.al")

    <<payload_small::binary-size(160), payload_medium::binary-size(1024),
      payload_big::binary-size(20_480), _rest::binary>> = payload

    %{
      "Small 160 B (typical RTP payload size)" => payload_small,
      "Medium 1024 B" => payload_medium,
      "Big 20480 B" => payload_big
    }
  end

  def runs() do
    {:ok, decoder_ref} = Decoder.Native.create()
    lut = LUT.Builder.build_alaw_to_linear()

    %{
      "FFmpeg NIFs" => fn payload -> benchmark_nif(payload, decoder_ref) end,
      "Map LUT in state" => fn payload -> benchmark_state(payload, lut) end,
      "Module attribute map LUT" => fn payload -> benchmark_mattr(payload) end,
      "Pattern match function LUT" => fn payload -> benchmark_pmf(payload) end
    }
  end

  defp benchmark_nif(payload, decoder_ref) do
    {:ok, [frame]} = Decoder.Native.decode(payload, decoder_ref)
    frame
  end

  defp benchmark_state(payload, lut) do
    for <<sample::8 <- payload>>, into: <<>> do
      <<lut[sample]::integer-signed-little-16>>
    end
  end

  defp benchmark_mattr(payload) do
    for <<sample::8 <- payload>>, into: <<>> do
      <<@lut[sample]::integer-signed-little-16>>
    end
  end

  defp benchmark_pmf(payload) do
    for <<sample::8 <- payload>>, into: <<>> do
      <<do_decode_pmf(sample)::integer-signed-little-16>>
    end
  end
end
