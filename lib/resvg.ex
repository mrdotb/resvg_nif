defmodule Resvg do
  @moduledoc """
  Documentation for `ResvgNif`.
  """

  def convert(input, output) do
    Resvg.Native.convert(input, output)
  end
end
