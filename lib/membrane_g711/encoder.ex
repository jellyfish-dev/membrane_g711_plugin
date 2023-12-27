defmodule Membrane.G711.Encoder do
  @moduledoc """
  Membrane element that encodes raw audio frames to G711 format (only A-law is supported).

  The element expects that each received buffer has whole samples, so the parser
  (`Membrane.Element.RawAudio.Parser`) may be required in a pipeline before
  the encoder. The amount of samples in a buffer may vary.

  Additionally, the encoder has to receive proper stream_format (see accepted format on input pad)
  before any encoding takes place.
  """

  use Membrane.Filter

  import Bitwise

  require Membrane.G711

  alias Membrane.G711.LUTBuilder
  alias Membrane.{G711, RawAudio}

  def_input_pad :input,
    flow_control: :auto,
    accepted_format: %RawAudio{
      channels: G711.num_channels(),
      sample_rate: G711.sample_rate(),
      sample_format: :s16le
    }

  def_output_pad :output,
    flow_control: :auto,
    accepted_format: %G711{encoding: :PCMA}

  @impl true
  def handle_init(_ctx, _opts) do
    state = %{encoding_lut: LUTBuilder.build_linear_to_alaw()}

    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, _ctx, state) do
    payload =
      buffer.payload
      |> Stream.unfold(fn
        <<>> -> nil
        <<chunk::binary-size(2), rest::binary>> -> {chunk, rest}
        _other -> raise "Failed to encode the payload: payload contains odd number of bytes"
      end)
      |> Stream.map(fn <<sample::integer-signed-little-16>> ->
        state.encoding_lut[(sample + 32_768) >>> 2]
      end)
      |> Enum.to_list()
      |> :binary.list_to_bin()

    {[buffer: {:output, [%Membrane.Buffer{payload: payload}]}], state}
  end

  @impl true
  def handle_stream_format(:input, _stream_format, _ctx, state) do
    stream_format = generate_stream_format(state)

    {[stream_format: {:output, stream_format}], state}
  end

  @impl true
  def handle_end_of_stream(:input, _ctx, state) do
    {[end_of_stream: :output], state}
  end

  defp generate_stream_format(_state) do
    %G711{encoding: :PCMA}
  end
end
