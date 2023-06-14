defmodule Resvg.Test do
  use ExUnit.Case

  @support_path Path.join(__DIR__, "support")

  def image_path(name) do
    Path.join(@support_path, name)
  end

  test "convert rustacean.svg to a png image" do
    input = image_path("rustacean.svg")
    output = image_path("rustacean.png")
    Resvg.convert(input, output)
    assert File.exists?(output)
  end
end
