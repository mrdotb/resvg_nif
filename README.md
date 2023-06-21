# Resvg (Rust NIFs for elixir)

[![Build Status](https://github.com/mrdotb/resvg_nif/workflows/Tests/badge.svg)](https://github.com/mrdotb/resvg_nif/workflows/Tests/badge.svg)

Resvg is an elixir library for the [resvg](https://github.com/RazrFalcon/resvg) library.

About resvg from its documentation:
> resvg is an SVG rendering library. The core idea is to make a fast, small, portable SVG library with the goal to support the whole SVG spec.

## About

Resvg is a **NIF** bindings libary for resvg.

* Try to support as much features as the resvg cli tool.
* Pre-compiled NIF

## Installation

The package can be installed
by adding `resvg_nif` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:resvg, "~> 0.1.0"}
  ]
end
```

## Livebook introduction

Easiest way to get started and try some stuff is to run the Livebook exemple.

[![Run in Livebook](https://livebook.dev/badge/v1/blue.svg)](https://livebook.dev/run?url=https%3A%2F%2Fgithub.com%2Fmrdotb%2Fresvg_nif%2Fblob%2Fmaster%2Flivebooks%2Fexemple.livemd)

## Contributing

You can contribute to resvg_nif. Please check the [CONTRIBUTING.md](CONTRIBUTING.md) guide for more information.

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to our [CODE_OF_CONDUCT.md](/CODE_OF_CONDUCT.md).

## Copyright and License

Copyright (c) 2023 Mrdotb

This work is free. You can redistribute it and / or modify it under the terms of the MIT License. See the LICENSE.md file for more details.
