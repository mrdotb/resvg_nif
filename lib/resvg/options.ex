defmodule Resvg.Options do
  @moduledoc """
  Options for Resvg.
  """

  @typedoc """
  The options for resvg functions.
  """

  @type resvg_option ::
          {:width, non_neg_integer()}
          | {:height, non_neg_integer()}
          | {:zoom, float()}
          | {:dpi, non_neg_integer()}
          | {:background, String.t()}
          | {:languages, [String.t()]}
          | {:shape_rendering, atom()}
          | {:text_rendering, atom()}
          | {:image_rendering, atom()}
          | {:resources_dir, Path.t()}
          | {:font_family, String.t()}
          | {:font_size, non_neg_integer()}
          | {:serif_family, String.t()}
          | {:sans_serif_family, String.t()}
          | {:cursive_family, String.t()}
          | {:fantasy_family, String.t()}
          | {:monospace_family, String.t()}
          | {:font_files, [Path.t()]}
          | {:font_dirs, [Path.t()]}
          | {:skip_system_fonts, boolean()}

  @type resvg_options :: [resvg_option()]

  defstruct width: nil,
            height: nil,
            zoom: nil,
            dpi: 96,
            background: nil,
            languages: ["en"],
            shape_rendering: "GeometricPrecision",
            text_rendering: "OptimizeLegibility",
            image_rendering: "OptimizeQuality",
            resources_dir: nil,
            font_family: nil,
            font_size: 12,
            serif_family: nil,
            sans_serif_family: nil,
            cursive_family: nil,
            fantasy_family: nil,
            monospace_family: nil,
            font_files: [],
            font_dirs: [],
            skip_system_fonts: false
end
