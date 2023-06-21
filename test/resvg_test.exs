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

    test "export to specific width height" do
      input = image_path("rustacean.svg")
      output = image_path("rustacean-120x80.png")
      assert :ok = Resvg.svg_to_png(input, output, width: 120, height: 80)
      assert File.exists?(output)
      assert md5(output) == "64b2cb45f5324b51b8949ce143f6f539"
    end

    test "set red background" do
      input = image_path("rustacean.svg")
      output = image_path("rustacean-red.png")
      assert :ok = Resvg.svg_to_png(input, output, background: "red")
      assert File.exists?(output)
      assert md5(output) == "1c3bb47193ae29f9aa844779f632cb8e"
    end

    test "fail background" do
      input = image_path("rustacean.svg")
      output = image_path("rustacean-bug.png")

      assert {:error, "Error background: invalid value"} =
               Resvg.svg_to_png(input, output, background: "bug")
    end

    test "zoom svg x2" do
      input = image_path("rustacean.svg")
      output = image_path("rustacean-zoom.png")
      assert :ok = Resvg.svg_to_png(input, output, zoom: 2.0)
      assert File.exists?(output)
      assert md5(output) == "8b94df6749215bc82373c58841df7e9c"
    end
  end

  describe "svg_string_to_png/3" do
    test "success convert svg string to a png image" do
      svg_string = """
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 15a4.5 4.5 0 004.5 4.5H18a3.75 3.75 0 001.332-7.257 3 3 0 00-3.758-3.848 5.25 5.25 0 00-10.233 2.33A4.502 4.502 0 002.25 15z" />
        </svg>
      """

      output = image_path("cloud.png")
      assert :ok = Resvg.svg_string_to_png(svg_string, output, resources_dir: @tmp)
      assert File.exists?(output)
      assert md5(output) == "d8407a3546efe75af450f2625f06d574"
    end

    test "render svg with image tag resolve from resources_dir" do
      output = image_path("image-test.png")

      svg_string = """
        <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200"
             xmlns:xlink="http://www.w3.org/1999/xlink"
        >
          <image xlink:href="mdn-logo.png" width="200" height="200" />
        </svg>
      """

      assert :ok = Resvg.svg_string_to_png(svg_string, output, resources_dir: @support_path)
      assert md5(output) == "5b18933af6a8a4f2ca623ecd7a5db626"
    end
  end

  describe "svg_string_to_png_buffer/3" do
    test "success convert svg string to a png image" do
      svg_string = """
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 15a4.5 4.5 0 004.5 4.5H18a3.75 3.75 0 001.332-7.257 3 3 0 00-3.758-3.848 5.25 5.25 0 00-10.233 2.33A4.502 4.502 0 002.25 15z" />
        </svg>
      """

      output = image_path("cloud-from-buf.png")
      assert {:ok, buffer} = Resvg.svg_string_to_png_buffer(svg_string, resources_dir: @tmp)
      :ok = File.write!(output, buffer)
      assert File.exists?(output)
      assert md5(output) == "d8407a3546efe75af450f2625f06d574"
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
      {:ok, [font]} =
        Resvg.list_fonts(skip_system_fonts: true, font_dirs: [font_dir()], resources_dir: @tmp)

      assert font =~ "Roboto"
    end

    test "success load a font file" do
      roboto = font_file("Roboto/Roboto-Regular.ttf")

      {:ok, [font]} =
        Resvg.list_fonts(skip_system_fonts: true, font_files: [roboto], resources_dir: @tmp)

      assert font =~ "Roboto"
    end

    test "fail load a font file" do
      roboto = font_file("Rototo/Rototo-Regular.ttf")

      {:error, error} =
        Resvg.list_fonts(skip_system_fonts: true, font_files: [roboto], resources_dir: @tmp)

      assert error == "Error loading font file: No such file or directory (os error 2)"
    end
  end
end
