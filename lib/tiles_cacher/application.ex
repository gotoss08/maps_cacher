defmodule TilesCacher.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: TilesCacher.Router, options: [port: 8080]}
    ]

    Logger.info("Starting application...")

    opts = [strategy: :one_for_one, name: TilesCacher.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
