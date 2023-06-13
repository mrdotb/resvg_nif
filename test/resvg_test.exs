defmodule ResvgTest do
  use ExUnit.Case
  doctest Resvg

  test "simple test" do
    input = Path.join(__DIR__, "rustacean.svg")
    output = Path.join(__DIR__, "rustacean.png")
    Resvg.convert(input, output)
  end
end
