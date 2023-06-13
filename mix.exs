defmodule Resvg.MixProject do
  use Mix.Project

  @source_url "https://github.com/mrdotb/resvg_nif"
  @version "0.1.0"

  def project do
    [
      app: :resvg,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      package: package(),
      name: "resvg",
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:rustler_precompiled, "~> 0.6.0"},
      {:rustler, "~> 0.25.0", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      description: "Responsive emails made easy. NIF bindings for ...",
      maintainers: ["Mrdotb"],
      licenses: ["MIT"],
      files: ~w(lib native .formatter.exs README* LICENSE* mix.exs checksum-*.exs),
      links: %{"GitHub" => @source_url}
    ]
  end

  defp aliases do
    [
      fmt: [
        "format",
        "cmd cargo fmt --manifest-path native/io/Cargo.toml"
      ]
    ]
  end
end
