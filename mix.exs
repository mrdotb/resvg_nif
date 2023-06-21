defmodule Resvg.MixProject do
  use Mix.Project

  @source_url "https://github.com/mrdotb/resvg_nif"
  @version "0.1.0"

  def project do
    [
      aliases: aliases(),
      app: :resvg,
      deps: deps(),
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "resvg",
      package: package(),
      start_permanent: Mix.env() == :prod,
      version: @version
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
      {:rustler, "~> 0.28.0", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      description: "Svg to png. NIF bindings for resvg.",
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
        "cmd cargo fmt --manifest-path native/resvg/Cargo.toml"
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]
end
