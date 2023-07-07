defmodule Resvg do
  @external_resource "README.md"

  @moduledoc """
  Provides functions to convert svg to png using resvg.

  ## Common options

  The supported options are:

    * `:width` - Set the width in pixels.
    * `:height` - Set the height in pixels.
    * `:zoom` - Zoom image by a factor, Example: `2.0`.
    * `:dpi` - Sets the resolution, default to `96`.
    * `:background` - Sets the background color, accept CSS3 color
    Example: `red`, `#fff`, `#fff000`.
    * `:languages` - Sets a list of languages that will be used during the
    `systemLanguage` attribute resolving, Example: `["en-US", "fr-FR"]`, default
    to `["en"]`.
    * `:shape_rendering` - Selects the default shape rendering method
    default to `:geometric_precision`.
    * `:text_rendering` - Selects the default text rendering method
    default to `:optimize_legibility`.
    * `:image_rendering` - Selects the default image rendering method
    default to `:optimize_quality`.
    * `:resources_dir` - Sets a directory that will be used during relative
    paths resolving. This field is mandatory for all functions
    except `svg_to_png/3` because it default to the `svg_input` path.
    * `:font_family` - Sets the default font family that will be used when
    no `font-family` is present, default to `Times New Roman`.
    * `:font_size` - Sets the default font size that will be used when no
    `font-size` is present, default to `12`.
    * `:serif_family` - Sets the `serif` font family, default to
    `Time New Roman`.
    * `:sans_serif_family` - Sets the `sans-serif` font family, default to
    `Arial`.
    * `:cursive_family` - Sets the `cursive` font family, default to
    `Comic Sans MS`.
    * `:fantasy_family` - Sets the `fantasy` font family, default to
    `Impact`.
    * `:monospace_family` - Sets the `monoscape` font family, default to
    `Courier New`.
    * `:font_files` - Load specified font files into the fonts database.
    * `:font_dirs` - Load all fonts from the specified directory into the fonts
    database.
    * `:skip_system_fonts` - Disable systems fonts loading. You should add some
    some fonts with `:font_files` or `:font_dirs` otherwise, text elements will
    not be processed.
  """

  alias Resvg.Options

  @doc """
  Try to convert the contents of `in_svg` to `out_png`.

  `in_svg` must be a path to a valid svg file.
  `out_png` must be a path to a non-existent file.
  `opts` refer to [options](#module-common-options)

  The functions return `:ok` in case of success. Otherise, it returns 
  `{:error, reason}` if an error occurs.

  ## Examples

      Resvg.svg_to_png("input.svg", "output.png")
      :ok

      Resvg.svg_to_png("doesnotexist.svg", "output.png")
      {:error, "Error loading svg file: No such file or directory (os error 2)"}
  """
  @spec svg_to_png(
          in_svg :: Path.t(),
          out_png :: Path.t(),
          options :: Options.resvg_options()
        ) :: :ok | {:error, String.t()}
  def svg_to_png(in_svg, out_png, opts \\ []) do
    options = struct(Options, opts)
    Resvg.Native.svg_to_png(in_svg, out_png, options)
  end

  @doc ~S"""
  Try to convert `svg_string` to `out_png`.

  `svg_string` must be a valid svg file.
  `out_png` must be a path to a non-existent file.
  `opts` refer to [options](#module-common-options) must at least set the
  `resources_dir` key to a valid path.

  The functions return `:ok` in case of success. Otherise, it returns 
  `{:error, reason}` if an error occurs.

  ## Examples

      svg_string = "
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
          <rect width="100" height="100" />
        </svg>"
      Resvg.svg_string_to_png(svg_string, "output.png", resources_dir: "/tmp")
      :ok
  """
  @spec svg_string_to_png(
          svg_string :: String.t(),
          out_png :: Path.t(),
          options :: Options.resvg_options()
        ) :: :ok | {:error, String.t()}
  def svg_string_to_png(svg_string, out_png, opts) do
    options = struct(Options, opts)
    Resvg.Native.svg_string_to_png(svg_string, out_png, options)
  end

  @doc ~S"""
  Try to convert `svg_string` to a png buffer..

  `svg_string` must be a valid svg file.
  `opts` refer to [options](#module-common-options) must at least set the
  `resources_dir` key to a valid path.

  The functions return `{:ok, buffer}` in case of success. Otherise, it returns 
  `{:error, reason}` if an error occurs.

  ## Examples

      svg_string = "
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20">
          <rect width="100" height="100" />
        </svg>"
      Resvg.svg_string_to_png(svg_string, "output.png", resources_dir: "/tmp")
      {:ok, buffer}
  """
  @spec svg_string_to_png_buffer(
          svg_string :: String.t(),
          options :: Options.resvg_options()
        ) :: {:ok, binary()} | {:error, String.t()}
  def svg_string_to_png_buffer(svg_string, opts) do
    options = struct(Options, opts)
    Resvg.Native.svg_string_to_png_buffer(svg_string, options)
  end

  @doc """
  List successfully loaded font faces. Useful for debugging.

  `opts` refer to [options](#module-common-options) must at least set the
  `resources_dir` key to a valid path.

  The functions return `{:ok, fonts_list}` in case of success. Otherise, it returns 
  `{:error, reason}` if an error occurs.

  ## Examples

      Resvg.list_fonts(resources_dir: "/tmp")
      {:ok, ["/usr/share/fonts/truetype/dejavu/DejaVuSansMono-BoldOblique.ttf..", ...]}
  """
  @spec list_fonts(options :: Options.resvg_options()) ::
          {:ok, [String.t()]} | {:error, String.t()}
  def list_fonts(opts) do
    options = struct(Options, opts)
    Resvg.Native.list_fonts(options)
  end

  @doc """
  Queries all valid SVG ids with bounding boxes

  `opts` refer to [options](#module-common-options)

  The functions return `{:ok, fonts_list}` in case of success. Otherise, it returns 
  `{:error, reason}` if an error occurs.

  ## Examples

      Resvg.query_all("rustacean.svg")
      [
        %Resvg.Native.Node{
          id: "Layer-1",
          x: -63.99300003051758,
          y: 90.14399719238281,
          width: 1304.344970703125,
          height: 613.6170043945312
        }
      ]
  """
  def query_all(in_svg, opts \\ []) do
    options = struct(Options, opts)
    Resvg.Native.query_all(in_svg, options)
  end
end
