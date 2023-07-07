defmodule Resvg.Native do
  @moduledoc false

  defmodule Node do
    defstruct ~w(id x y width height)a
  end

  mix_config = Mix.Project.config()
  version = mix_config[:version]
  github_url = mix_config[:package][:links]["GitHub"]

  use RustlerPrecompiled,
    otp_app: :resvg,
    crate: "resvg",
    base_url: "#{github_url}/releases/download/v#{version}",
    force_build: System.get_env("RESVG_BUILD") in ["1", "true"],
    version: version,
    targets: ~w(
      arm-unknown-linux-gnueabihf
      aarch64-apple-darwin
      aarch64-unknown-linux-gnu
      aarch64-unknown-linux-musl
      riscv64gc-unknown-linux-gnu
      x86_64-apple-darwin
      x86_64-pc-windows-gnu
      x86_64-pc-windows-msvc
      x86_64-unknown-linux-gnu
      x86_64-unknown-linux-musl
    )s

  def svg_to_png(_in_svg, _out_png, _options), do: error()
  def svg_string_to_png(_svg_string, _png_path, _options), do: error()
  def svg_string_to_png_buffer(_svg_string, _options), do: error()
  def list_fonts(_options), do: error()
  def query_all(_in_svg, _options), do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
