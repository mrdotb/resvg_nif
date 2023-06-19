defmodule Resvg.Test do
  use ExUnit.Case

  @support_path Path.join(__DIR__, "support")
  @tmp System.tmp_dir!()

  defp image_path(name) do
    Path.join(@support_path, name)
  end

  defp font_dir do
    Path.join(@support_path, "fonts")
  end

  defp font_file(name) do
    Path.join(font_dir(), name)
  end

  defp md5(path) do
    binary = File.read!(path)

    :md5
    |> :crypto.hash(binary)
    |> Base.encode16(case: :lower)
  end

  describe "svg_to_png/3" do
    test "success convert rustacean.svg to a png image" do
      input = image_path("rustacean.svg")
      output = image_path("rustacean.png")
      assert :ok = Resvg.svg_to_png(input, output)
      assert File.exists?(output)
      assert md5(output) == "317281192ae68db988da23edb5387dab"
    end

    test "fail input does not exist" do
      input = image_path("doesnotexist.svg")
      output = image_path("doesnotexist.png")
      assert {:error, msg} = Resvg.svg_to_png(input, output)
      assert msg == "Error loading svg file: No such file or directory (os error 2)"
    end

    test "set red background" do
      input = image_path("rustacean.svg")
      output = image_path("rustacean-red.png")
      assert :ok = Resvg.svg_to_png(input, output, background: "red")
      assert File.exists?(output)
      assert md5(output) == "1c3bb47193ae29f9aa844779f632cb8e"
    end

    test "background" do
      input = image_path("rustacean.svg")
      output = image_path("rustacean-bug.png")
      assert {:error, "Error background: invalid value"} = Resvg.svg_to_png(input, output, background: "bug")
    end
  end

  describe "list_fonts/1" do
    test "return fonts list" do
      {:ok, fonts} = Resvg.list_fonts(resources_dir: @tmp)
      assert is_list(fonts)
    end

    test "without system fonts" do
      {:ok, fonts} = Resvg.list_fonts(skip_system_fonts: true, resources_dir: @tmp)
      assert Enum.empty?(fonts)
    end

    test "load fonts from dirs" do
      {:ok, [font]} = Resvg.list_fonts(skip_system_fonts: true, font_dirs: [font_dir()], resources_dir: @tmp)
      assert font =~ "Roboto"
    end

    test "success load a font file" do
      roboto = font_file("Roboto/Roboto-Regular.ttf")
      {:ok, [font]} = Resvg.list_fonts(skip_system_fonts: true, font_files: [roboto], resources_dir: @tmp)
      assert font =~ "Roboto"
    end

    test "fail load a font file" do
      roboto = font_file("Rototo/Rototo-Regular.ttf")
      {:error, error} = Resvg.list_fonts(skip_system_fonts: true, font_files: [roboto], resources_dir: @tmp)
      assert error == "Error loading font file: No such file or directory (os error 2)"
    end
  end
end
