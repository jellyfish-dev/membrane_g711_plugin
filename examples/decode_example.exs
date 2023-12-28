# Decoding example
#
# The following pipeline takes a G.711 A-law file and decodes it to the raw audio.

Logger.configure(level: :info)

Mix.install([
  {:membrane_g711_plugin, path: __DIR__ |> Path.join("..") |> Path.expand(), override: true},
  :membrane_hackney_plugin
])

defmodule Decoding.Pipeline do
  use Membrane.Pipeline

  @impl true
  def handle_init(_ctx, _opts) do
    spec =
      child(:source, %Membrane.Hackney.Source{
        location:
          "https://raw.githubusercontent.com/membraneframework/static/gh-pages/samples/beep-alaw-8kHz-mono.raw"
      })
      |> child(:decoder, Membrane.G711.Decoder)
      |> child(:sink, %Membrane.File.Sink{location: "output.raw"})

    {[spec: spec], %{}}
  end

  @impl true
  def handle_element_end_of_stream(:sink, _pad, _ctx, state) do
    {[terminate: :shutdown], state}
  end

  @impl true
  def handle_element_end_of_stream(_child, _pad, _ctx, state) do
    {[], state}
  end
end

# Start and monitor the pipeline
{:ok, _supervisor_pid, pipeline_pid} = Membrane.Pipeline.start_link(Decoding.Pipeline)
ref = Process.monitor(pipeline_pid)

# Wait for the pipeline to finish
receive do
  {:DOWN, ^ref, :process, _pipeline_pid, _reason} ->
    System.stop()
end
