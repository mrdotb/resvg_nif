defmodule Resvg.Options do
  @moduledoc false
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
