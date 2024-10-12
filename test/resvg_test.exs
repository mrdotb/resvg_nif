defmodule Resvg.Test do
  use ExUnit.Case
  import Approval

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

  describe "svg_to_png/3" do
    test "success convert rustacean.svg to a png image" do
      input = image_path("rustacean.svg")
      output = image_path("snapshots/rustacean.png")
      reference = image_path("rustacean-reference.png")

      assert :ok = Resvg.svg_to_png(input, output)
      assert File.exists?(output)

      approve(
        snapshot: File.read!(output),
        reference: File.read!(reference),
        reviewed: true
      )
    end

    test "fail input does not exist" do
      input = image_path("doesnotexist.svg")
      output = image_path("doesnotexist.png")
      assert {:error, msg} = Resvg.svg_to_png(input, output)
      assert msg == "Error loading svg file: No such file or directory (os error 2)"
    end

    test "export to specific width height" do
      input = image_path("rustacean.svg")
      output = image_path("snapshots/rustacean-120x80.png")
      reference = image_path("rustacean-120x80-reference.png")

      assert :ok = Resvg.svg_to_png(input, output, width: 120, height: 80)
      assert File.exists?(output)

      approve(
        snapshot: File.read!(output),
        reference: File.read!(reference),
        reviewed: true
      )
    end

    test "set red background" do
      input = image_path("rustacean.svg")
      output = image_path("snapshots/rustacean-red.png")
      reference = image_path("rustacean-red-reference.png")

      assert :ok = Resvg.svg_to_png(input, output, background: "red")
      assert File.exists?(output)

      approve(
        snapshot: File.read!(output),
        reference: File.read!(reference),
        reviewed: true
      )
    end

    test "fail background" do
      input = image_path("rustacean.svg")
      output = image_path("rustacean-bug.png")

      assert {:error, "Error background: invalid value"} =
               Resvg.svg_to_png(input, output, background: "bug")
    end

    test "zoom svg x2" do
      input = image_path("rustacean.svg")
      output = image_path("snapshots/rustacean-zoom.png")
      reference = image_path("rustacean-zoom-reference.png")

      assert :ok = Resvg.svg_to_png(input, output, zoom: 2.0)
      assert File.exists?(output)

      approve(
        snapshot: File.read!(output),
        reference: File.read!(reference),
        reviewed: true
      )
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
      reference = image_path("cloud-reference.png")

      assert :ok = Resvg.svg_string_to_png(svg_string, output, resources_dir: @tmp)
      assert File.exists?(output)

      approve(
        snapshot: File.read!(output),
        reference: File.read!(reference),
        reviewed: true
      )
    end

    test "render svg with image tag resolve from resources_dir" do
      output = image_path("snapshots/image-test.png")
      reference = image_path("image-test-reference.png")

      svg_string = """
        <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200"
             xmlns:xlink="http://www.w3.org/1999/xlink"
        >
          <image xlink:href="mdn-logo.png" width="200" height="200" />
        </svg>
      """

      assert :ok = Resvg.svg_string_to_png(svg_string, output, resources_dir: @support_path)

      approve(
        snapshot: File.read!(output),
        reference: File.read!(reference),
        reviewed: true
      )
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
      reference = image_path("cloud.png")

      assert {:ok, buffer} = Resvg.svg_string_to_png_buffer(svg_string, resources_dir: @tmp)
      :ok = File.write!(output, buffer)
      assert File.exists?(output)

      approve(
        snapshot: File.read!(output),
        reference: File.read!(reference),
        reviewed: true
      )
    end
  end

  describe "revg deals correctly with <tspan> elements inside a <text> element" do
    # NOTE (tmbb)
    # This is a minimal reproducible test case for a bug I found in resvg before v0.40.
    # I don't know why this specific example triggered the bug, but it's a useful test
    # case to keep in case there is some regression in Resvg

    # Because of repetitiveness in the rust rendering functions,
    # we test the behaviour in all of them.
    test "- function svg_string_to_png/3" do
      input = image_path("text-font-change.svg")
      output = image_path("snapshots/text-font-change_svg_string_to_png.png")
      reference = image_path("text-font-change-reference.png")

      svg_string = File.read!(input)

      :ok =
        Resvg.svg_string_to_png(svg_string, output,
          dpi: 256,
          skip_system_fonts: true,
          resources_dir: @tmp,
          font_dirs: [font_dir()]
        )

      approve(
        snapshot: File.read!(output),
        reference: File.read!(reference),
        reviewed: true
      )
    end

    test "- function svg_string_to_png_buffer/3" do
      input = image_path("text-font-change.svg")
      output = image_path("snapshots/text-font-change_svg_string_to_png_buffer.png")
      reference = image_path("text-font-change-reference.png")

      svg_string = File.read!(input)

      {:ok, image_data} =
        Resvg.svg_string_to_png_buffer(svg_string,
          dpi: 256,
          skip_system_fonts: true,
          resources_dir: @tmp,
          font_dirs: [font_dir()]
        )

      # Write it out becuase it's easier
      File.write!(output, image_data)

      approve(
        snapshot: File.read!(output),
        reference: File.read!(reference),
        reviewed: true
      )
    end

    test "- function svg_to_png/3" do
      input = image_path("text-font-change.svg")
      output = image_path("snapshots/text-font-change_svg_to_png.png")
      reference = image_path("text-font-change-reference.png")

      :ok =
        Resvg.svg_to_png(input, output,
          dpi: 256,
          skip_system_fonts: true,
          resources_dir: @tmp,
          font_dirs: [font_dir()]
        )

      approve(
        snapshot: File.read!(output),
        reference: File.read!(reference),
        reviewed: true
      )
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
      {:ok, fonts} =
        Resvg.list_fonts(skip_system_fonts: true, font_dirs: [font_dir()], resources_dir: @tmp)

      assert is_list(fonts)
      assert length(fonts) == 3

      assert Enum.any?(fonts, fn f -> f =~ "Roboto" end)
      assert Enum.any?(fonts, fn f -> f =~ "LinLibertine" end)
      assert Enum.any?(fonts, fn f -> f =~ "Ubuntu" end)
    end

    test "success load a font file" do
      roboto = font_file("Roboto-Regular.ttf")

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

  describe "query_all/2" do
    test "returns id list" do
      input = image_path("rustacean.svg")

      [node] = Resvg.query_all(input)

      assert node.id == "Layer-1"
      assert_in_delta(node.x, 13.1080, 0.0001)
      assert_in_delta(node.y, 90.14399, 0.0001)
      assert_in_delta(node.width, 1170.8819, 0.0001)
      assert_in_delta(node.height, 612.8910, 0.0001)
    end

    test "measures text elements if the right font files are given" do
      roboto = font_file("Roboto-Regular.ttf")

      input = image_path("text-measurement.svg")

      [node] = Resvg.query_all(input, font_files: [roboto], resources_dir: @tmp)

      assert node.id == "Text-Element-1"
      assert_in_delta(node.x, 0.2870, 0.0001)
      assert_in_delta(node.y, -8.5310, 0.0001)
      assert_in_delta(node.width, 85.1839, 0.0001)
      assert_in_delta(node.height, 8.6479, 0.0001)
    end

    test "doesn't measure text elements if the right font files are not given" do
      input = image_path("text-measurement.svg")

      assert Resvg.query_all(input, font_files: []) == []
    end
  end
end
