defmodule Resvg.Native do
  # mix_config = Mix.Project.config()
  # version = mix_config[:version]
  # github_url = mix_config[:package][:links]["GitHub"]

  # targets = ~w(
  #   arm-unknown-linux-gnueabihf
  #   aarch64-apple-darwin
  #   aarch64-unknown-linux-gnu
  #   aarch64-unknown-linux-musl
  #   riscv64gc-unknown-linux-gnu
  #   x86_64-apple-darwin
  #   x86_64-pc-windows-gnu
  #   x86_64-pc-windows-msvc
  #   x86_64-unknown-linux-gnu
  #   x86_64-unknown-linux-musl
  # )

  # use RustlerPrecompiled,
  #   otp_app: :resvg,
  #   crate: "resvg_nif",
  #   base_url: "#{github_url}/releases/download/v#{version}",
  #   force_build: System.get_env("MJML_BUILD") in ["1", "true"],
  #   version: version,
  #   targets: targets

  use Rustler, otp_app: :resvg, crate: :resvg

  def convert(_mjml, _render_options), do: error()
  defp error(), do: :erlang.nif_error(:nif_not_loaded)
end
