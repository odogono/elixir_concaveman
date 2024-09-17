defmodule Concaveman.MixProject do
  use Mix.Project

  def project do
    [
      app: :concaveman,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: [:build_dot_zig] ++ Mix.compilers()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Concaveman.Application, []},
      extra_applications: [:logger, :observer, :wx, :runtime_tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:build_dot_zig, "~> 0.5.0", runtime: false},
      {:phoenix_playground, "~> 0.1.6", only: [:dev], runtime: false}
    ]
  end
end
