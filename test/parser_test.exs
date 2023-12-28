defmodule ParserTest do
  use ExUnit.Case, async: true
  use Membrane.Pipeline

  import Membrane.Testing.Assertions

  require Membrane.G711

  alias Membrane.G711.Parser
  alias Membrane.Testing.{Pipeline, Sink, Source}
  alias Membrane.{Buffer, G711, RawAudio, Time}

  @faux_stream_format %RawAudio{
    channels: G711.num_channels(),
    sample_rate: G711.sample_rate(),
    sample_format: :s8
  }

  @stream_format %G711{encoding: :PCMA}

  @silence_duration Time.milliseconds(10)
  @silence RawAudio.silence(@faux_stream_format, @silence_duration)

  test "parser adds timestamps" do
    perform_parsing_test_with_buffer_checks()
  end

  test "parser adds timestamps with offset" do
    perform_parsing_test_with_buffer_checks(10)
  end

  test "parser can have `RemoteStream` as input" do
    perform_parsing_test(
      %Membrane.File.Source{location: "test/fixtures/decode/input.al"},
      %Parser{stream_format: @stream_format}
    )
  end

  defp perform_parsing_test_with_buffer_checks(offset \\ 0) do
    buffers = Enum.map(1..10, fn _idx -> @silence end)

    parser_spec =
      if offset != 0,
        do: %Parser{overwrite_pts?: true, pts_offset: offset},
        else: %Parser{overwrite_pts?: true}

    pipeline =
      perform_parsing_test(%Source{output: buffers, stream_format: @stream_format}, parser_spec)

    for i <- 0..9 do
      pts = i * @silence_duration + offset
      assert_sink_buffer(pipeline, :sink, %Buffer{pts: ^pts, payload: @silence})
    end
  end

  defp perform_parsing_test(source_spec, parser_spec) do
    spec = [
      child(:source, source_spec)
      |> child(:parser, parser_spec)
      |> child(:sink, Sink)
    ]

    assert pipeline = Pipeline.start_link_supervised!(spec: spec)
    assert_end_of_stream(pipeline, :sink)

    pipeline
  end
end
