defmodule Resvg do
  @moduledoc """
  Documentation for `ResvgNif`.
  """

  def svg_to_png(svg_path, png_path, opts \\ []) do
    options = struct(Resvg.Options, opts)
    Resvg.Native.svg_to_png(svg_path, png_path, options)
  end

  def list_fonts(opts \\ []) do
    options = struct(Resvg.Options, opts)
    Resvg.Native.list_fonts(options)
  end
end
