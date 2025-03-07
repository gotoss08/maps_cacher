defmodule TilesCacher.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Welcome")
  end

  get "/ping" do
    send_resp(conn, 200, "pong")
  end

  get "/tile/:provider/:type/:z/:x/:y/:img_extension" do
    request_tile_data = %{
      provider: provider,
      type: type,
      x: x,
      y: y,
      z: z,
      img_extension: img_extension
    }

    case TilesCacher.fetch_tile(request_tile_data) do
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
