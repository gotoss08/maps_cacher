defmodule TilesCacher.MixProject do
  use Mix.Project

  def project do
    [
      app: :maps_cacher,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_options: [warnings_as_errors: true]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {TilesCacher.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:exsync, "~> 0.4.1", only: :dev},
      {:plug_cowboy, "~> 2.7"},
      {:req, "~> 0.5.8"}
    ]
  end
end
