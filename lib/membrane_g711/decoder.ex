defmodule Membrane.G711.Decoder do
  @moduledoc """
  Membrane element that decodes audio in G711 format.

  At the moment, only A-law is supported.
  """

  use Membrane.Filter

  require Membrane.G711

  alias Membrane.{G711, RawAudio, RemoteStream}

  @sample_format :s16le

  def_input_pad :input,
    flow_control: :auto,
    accepted_format: any_of(%RemoteStream{}, %G711{encoding: :PCMA})

  def_output_pad :output,
    flow_control: :auto,
    accepted_format: %RawAudio{
      channels: G711.num_channels(),
      sample_rate: G711.sample_rate()
    }

  @impl true
  def handle_init(_ctx, _opts) do
    state = %{}

    {[], state}
  end

  @impl true
  def handle_buffer(:input, %{payload: payload}, _ctx, state) do
    for <<sample::8 <- payload>>, into: <<>> do
      <<G711.LUT.alaw_decode(sample)::integer-signed-little-16>>
    end
    |> then(&{[buffer: {:output, [%Membrane.Buffer{payload: &1}]}], state})
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
    %RawAudio{
      channels: G711.num_channels(),
      sample_rate: G711.sample_rate(),
      sample_format: @sample_format
    }
  end
end
