defmodule TilesCacher.RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias TilesCacher.Router

  @opts Router.init([])

  test "ping" do
    conn =
      :get
      |> conn("/ping", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "pong"
  end

  test "returns welcome" do
    conn =
      :get
      |> conn("/", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "Welcome"
  end
end
