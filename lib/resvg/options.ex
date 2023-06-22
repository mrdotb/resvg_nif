defmodule Resvg.Options do
  @moduledoc """
  Options for Resvg.
  """

  @typedoc """
  The options for resvg functions.
  """

  @type shape_rendering :: :optimize_speed | :crisp_edges | :geometric_precision
  @type text_rendering :: :optimize_speed | :optimize_legibility | :geometric_precision
  @type image_rendering :: :optimize_quality | :optimize_speed

  @type resvg_options :: [
          {:width, non_neg_integer()}
          | {:height, non_neg_integer()}
          | {:zoom, float()}
          | {:dpi, 10..4000}
          | {:background, String.t()}
          | {:languages, [String.t()]}
          | {:shape_rendering, shape_rendering()}
          | {:text_rendering, text_rendering()}
          | {:image_rendering, image_rendering()}
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
        ]

  defstruct width: nil,
            height: nil,
            zoom: nil,
            dpi: 96,
            background: nil,
            languages: ["en"],
            shape_rendering: :geometric_precision,
            text_rendering: :optimize_legibility,
            image_rendering: :optimize_quality,
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
