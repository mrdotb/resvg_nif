# Resvg (Rust NIFs for elixir)

[![Build Status](https://github.com/mrdotb/resvg_nif/workflows/Tests/badge.svg)](https://github.com/mrdotb/resvg_nif/workflows/Tests/badge.svg)
[![Module Version](https://img.shields.io/hexpm/v/resvg.svg)](https://hex.pm/packages/resvg)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/resvg)
[![Total Download](https://img.shields.io/hexpm/dt/resvg.svg)](https://hex.pm/packages/resvg)
[![License](https://img.shields.io/hexpm/l/resvg.svg)](https://github.com/mrdotb/resvg_nif/blob/master/LICENSE.md)

Native Implemented Function (NIF) bindings for the [resvg](https://github.com/RazrFalcon/resvg) library.

About resvg from its documentation:
> resvg is an SVG rendering library. The core idea is to make a fast, small, portable SVG library with the goal to support the whole SVG spec.

## Installation

The package can be installed
by adding `resvg_nif` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:resvg, "~> 0.3.0"}
  ]
end
```

## Usage

Convert svg to png with:

```elixir
:ok = Resvg.svg_to_png("input.svg", "output.png")

svg_string = """
<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" d="M2.25 15a4.5 4.5 0 004.5 4.5H18a3.75 3.75 0 001.332-7.257 3 3 0 00-3.758-3.848 5.25 5.25 0 00-10.233 2.33A4.502 4.502 0 002.25 15z" />
</svg>
"""
:ok = Resvg.svg_string_to_png(svg_string, "output.png", resources_dir: "/tmp")
```

## Livebook introduction

Easiest way to get started and try more advanced example is is to run the Livebook.

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fmrdotb%2Fresvg_nif%2Fblob%2Fmaster%2Flivebooks%2Fexample.livemd)

## Contributing

You can contribute to resvg_nif. Please check the [CONTRIBUTING.md](CONTRIBUTING.md) guide for more information.

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to our [CODE_OF_CONDUCT.md](/CODE_OF_CONDUCT.md).

## Copyright and License

Copyright (c) 2023 Mrdotb

This work is free. You can redistribute it and / or modify it under the terms of the MIT License. See the LICENSE.md file for more details.
