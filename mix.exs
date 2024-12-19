defmodule Resvg.MixProject do
  use Mix.Project

  @source_url "https://github.com/mrdotb/resvg_nif"
  @version "0.4.0"

  def project do
    [
      aliases: aliases(),
      app: :resvg,
      deps: deps(),
      docs: docs(),
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
      {:rustler_precompiled, "~> 0.8.1"},
      {:rustler, "~> 0.35.1", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:approval, "~> 0.1", only: :test}
    ]
  end

  defp package do
    [
      description: "Svg to png. NIF bindings for resvg.",
      maintainers: ["Mrdotb"],
      licenses: ["MIT"],
      files: ~w(
        lib native .formatter.exs README.md LICENSE.md CHANGELOG.md mix.exs checksum-*.exs
      )s,
      links: %{"GitHub" => @source_url}
    ]
  end

  def docs do
    [
      source_ref: "master",
      main: "readme",
      extras: [
        "CHANGELOG.md": [],
        "CONTRIBUTING.md": [title: "Contributing"],
        "CODE_OF_CONDUCT.md": [title: "Code of Conduct"],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      source_url: @source_url,
      source_ref: "v#{@version}",
      homepage_url: @source_url,
      formatters: ["html"]
    ]
  end

  defp aliases do
    [
      "format.all": [
        "format",
        "cmd cargo fmt --manifest-path native/resvg/Cargo.toml"
      ],
      "format.check": [
        "format --check-formatted",
        "cmd cargo fmt --manifest-path native/resvg/Cargo.toml -- --check"
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(_), do: ["lib"]
end
