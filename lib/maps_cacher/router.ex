defmodule MapsCacher.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Welcome")
  end

  get "/ping" do
    send_resp(conn, 200, "pong")
  end

  get "/map/:provider/:type/:z/:x/:y" do
    rest_body =
      """
      provider : "#{provider}"
      type     : "#{type}"
      z        : "#{z}"
      x        : "#{x}"
      y        : "#{y}"
      """

    case MapsCacher.fetch_tile(provider, type, z, x, y) do
      {:ok, tile} ->
        conn
        |> put_resp_header("content-type", tile.content_type)
        |> send_resp(200, tile.data)

      {:error, {code, message}} ->
        conn
        |> send_resp(code, message)
    end
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
