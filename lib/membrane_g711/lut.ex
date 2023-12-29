defmodule Membrane.G711.LUT do
  @moduledoc false

  import Bitwise

  alias Membrane.G711.LUT.Builder

  def alaw_encode(sample), do: do_alaw_encode((sample + 32_768) |> bsr(2))
  def alaw_decode(sample), do: do_alaw_decode(sample)

  for {linear, alaw} <- Builder.build_linear_to_alaw() do
    defp do_alaw_encode(unquote(linear)), do: unquote(alaw)
  end

  for {alaw, linear} <- Builder.build_alaw_to_linear() do
    defp do_alaw_decode(unquote(alaw)), do: unquote(linear)
  end
end
