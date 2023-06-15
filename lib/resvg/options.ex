defmodule Resvg.Options do
  @moduledoc false
  defstruct width: nil,
            height: nil,
            zoom: nil,
            dpi: nil,
            background: nil,
            languages: nil,
            shape_rendering: nil,
            text_rendering: nil,
            image_rendering: nil,
            resources_dir: nil,
            font_family: nil,
            font_size: nil,
            serif_family: nil,
            sans_serif_family: nil,
            cursive_family: nil,
            fantasy_family: nil,
            monospace_family: nil,
            use_font_file: nil,
            use_font_dir: nil,
            skip_system_fonts: false
end
