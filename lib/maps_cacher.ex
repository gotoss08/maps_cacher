defmodule TilesCacher do
  require Logger

  def fetch_tile(provider, type, z, x, y) do
    path = get_tile_cache_path(provider, type, z, x, y)

    # Ensure directory exists
    path
    |> Path.dirname()
    |> File.mkdir_p!()

    # Check if file exists
    if File.exists?(path) do
      case File.read(path) do
        {:ok, data} ->
          Logger.info("Serving tile: \"#{path}\" from local cache")
          {:ok, %{content_type: "image/jpeg", data: data}}

        {:error, reason} ->
          Logger.error("Failed to read existing file: #{inspect(reason)}")
          download_tile(provider, type, z, x, y)
      end
    else
      # Tile doesn't exist, download it
      download_tile(provider, type, z, x, y)
    end
  end

  defp get_tile_cache_path(provider, type, z, x, y),
    do: "tiles/#{provider}/#{type}/#{z}/#{x}/#{y}.jpeg"

  defp resolve_type(provider, type) when provider == "google" do
    case type do
      "standard" -> "m"
      "satellite" -> "s"
      "hybrid" -> "y"
      "terrain" -> "p"
    end
  end

  defp resolve_type(_, type), do: type

  defp download_tile(provider, type, z, x, y) when provider == "google" do
    Logger.info("Downloading tile: \"#{provider}/#{type}/#{z}/#{x}/#{y}\"")

    pattern = "https://mt1.google.com/vt/lyrs={type}&x={x}&y={y}&z={z}"

    request_url =
      pattern
      |> String.replace("{type}", resolve_type(provider, type))
      |> String.replace("{x}", x)
      |> String.replace("{y}", y)
      |> String.replace("{z}", z)

    Logger.info("Google Maps request: \"#{request_url}\"")

    headers = [
      user_agent:
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36",
      sec_ch_ua_platform: "Windows",
      sec_ch_ua_mobile: "?0",
      sec_ch_ua: "\"Not(A:Brand\";v=\"99\", \"Google Chrome\";v=\"133\"",
      upgrade_insecure_requests: "1"
    ]

    # Get tile from server
    resp =
      Req.get(request_url, headers: headers)
      |> handle_response

    case resp do
      {:ok, tile} ->
        # Write binary data to a file
        path = get_tile_cache_path(provider, type, z, x, y)
        File.write(path, tile.data, [:write])
        Logger.info("Cached tile: \"#{path}\"")
    end

    resp
  end

  defp download_tile(provider, _type, _z, _x, _y) when provider == "osm" do
    raise RuntimeError, "TilesCacher.download_tile/5 for OSM is not implemented yet"
  end

  # Response handlers

  defp handle_response({:ok, resp}) when resp.status == 200 do
    resp_body = resp.body
    content_type = hd(resp.headers["content-type"])
    {:ok, %{content_type: content_type, data: resp_body}}
  end

  defp handle_response({:ok, resp}),
    do: return_error("Google maps service status: #{resp.status}")

  defp handle_response({:error, exception}), do: return_error(exception)

  # Error handlers

  defp return_error(%{message: msg}) do
    {:error, {502, msg}}
  end

  defp return_error(msg) when is_binary(msg) do
    {:error, {502, msg}}
  end

  defp return_error(_) do
    {:error, {502, "Unknown error"}}
  end
end
