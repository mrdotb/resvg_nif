defmodule Resvg do
  @moduledoc """
  Documentation for `ResvgNif`.
  """

  def svg_to_png(in_svg, out_png, opts \\ []) do
    options = struct(Resvg.Options, opts)
    Resvg.Native.svg_to_png(in_svg, out_png, options)
  end

  def svg_string_to_png(svg_string, out_png, opts \\ []) do
    options = struct(Resvg.Options, opts)
    Resvg.Native.svg_string_to_png(svg_string, out_png, options)
  end

  def svg_string_to_png_buffer(svg_string, opts \\ []) do
    options = struct(Resvg.Options, opts)
    Resvg.Native.svg_string_to_png_buffer(svg_string, options)
  end

  def list_fonts(opts \\ []) do
    options = struct(Resvg.Options, opts)
    Resvg.Native.list_fonts(options)
  end
end
