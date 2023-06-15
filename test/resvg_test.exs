defmodule Resvg.Test do
  use ExUnit.Case

  @support_path Path.join(__DIR__, "support")

  def image_path(name) do
    Path.join(@support_path, name)
  end

  test "svg_to_png/3 convert rustacean.svg to a png image" do
    input = image_path("rustacean.svg")
    output = image_path("rustacean.png")
    assert :ok = Resvg.svg_to_png(input, output)
    assert File.exists?(output)
  end

  test "list_fonts/1 return fonts list" do
    fonts = Resvg.list_fonts()
    assert is_list(fonts)
  end

  test "list_fonts/1 without system fonts" do
    fonts = Resvg.list_fonts(skip_system_fonts: true)
    assert Enum.empty?(fonts)
  end
end
