# Concaveman

Experiment in integrating cpp version of concaveman into Elixir.

Running

```
iex -S mix
```

will start a server at http://localhost:4000 into which you can drag and drop GeoJSON files. Concaveman will be run on the data and the result will be displayed in the browser.

This server uses https://github.com/phoenix-playground/phoenix_playground to provide a live view interface.

The build uses https://github.com/rbino/build_dot_zig to compile the Zig code to a NIF.

The Zig build is set to optimised, otherwise it's comparitively slow compared to the JS version.


TODO:

- [ ] The JS version of concaveman gives better results for the same inputs.
- [ ] Calculation of the initial concave hull is calculated in elixir, so should be moved to Zig
- [ ] Cleanup of code and removal of dead code


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `elixir_concaveman` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elixir_concaveman, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/elixir_concaveman>.

