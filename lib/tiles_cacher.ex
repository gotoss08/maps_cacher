defmodule TilesCacher do
  require Logger

  def fetch_tile(request_tile_data) do
    tile_img_path = get_tile_cache_path(request_tile_data)

    # Ensure directory exists
    tile_img_path
    |> Path.dirname()
    |> File.mkdir_p!()

    # Check if file exists
    if File.exists?(tile_img_path) do
      case File.read(tile_img_path) do
        {:ok, data} ->
          Logger.info("Serving tile: \"#{tile_img_path}\" from local cache")
          {:ok, %{content_type: MIME.type(request_tile_data.img_extension), data: data}}

        {:error, reason} ->
          Logger.error("Failed to read existing file: #{inspect(reason)}")
          download_tile(request_tile_data)
      end
    else
      # Tile doesn't exist, download it
      download_tile(request_tile_data)
    end
  end

  defp get_tile_cache_path(%{
         provider: provider,
         type: type,
         x: x,
         y: y,
         z: z,
         img_extension: img_extension
       }),
       do: "tiles/#{provider}/#{type}/#{z}/#{x}/#{y}.#{img_extension}"

  defp resolve_type(provider, type) when provider == "google" do
    case type do
      "standard" -> "m"
      "satellite" -> "s"
      "hybrid" -> "y"
      "terrain" -> "p"
    end
  end

  defp resolve_type(_, type), do: type

  defp resolve_tile_download_url(%{
         provider: provider,
         type: type,
         x: x,
         y: y,
         z: z
       })
       when provider == "google" do
    pattern = "https://mt1.google.com/vt/lyrs={type}&x={x}&y={y}&z={z}"

    request_url =
      pattern
      |> String.replace("{type}", resolve_type(provider, type))
      |> String.replace("{x}", x)
      |> String.replace("{y}", y)
      |> String.replace("{z}", z)

    Logger.info("Google Maps request: \"#{request_url}\"")

    request_url
  end

  defp resolve_tile_download_url(%{
         provider: provider,
         x: x,
         y: y,
         z: z
       })
       when provider == "osm" do
    pattern = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"

    request_url =
      pattern
      |> String.replace("{x}", x)
      |> String.replace("{y}", y)
      |> String.replace("{z}", z)

    Logger.info("OSM request: \"#{request_url}\"")

    request_url
  end

  defp resolve_tile_download_url(%{
         provider: provider
       }) do
    raise RuntimeError,
          "TilesCacher.download_tile/5 for provider \"#{provider}\" is not implemented yet"
  end

  defp resolve_user_agent(provider) when provider == "osm" do
    "huntermap-tiles-cacher"
  end

  defp resolve_user_agent(_) do
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36"
  end

  defp download_tile(
         %{
           provider: provider,
           type: type,
           x: x,
           y: y,
           z: z,
           img_extension: img_extension
         } = request_tile_data
       ) do
    Logger.info("Downloading tile: \"#{provider}/#{type}/#{z}/#{x}/#{y}/#{img_extension}\"")

    request_url = resolve_tile_download_url(request_tile_data)

    headers = [
      user_agent: resolve_user_agent(provider),
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
        path = get_tile_cache_path(request_tile_data)
        File.write(path, tile.data, [:write])
        Logger.info("Cached tile: \"#{path}\"")
        resp

      _ ->
        resp
    end
  end

  # Response handlers

  defp handle_response({:ok, resp}) when resp.status == 200 do
    resp_body = resp.body
    content_type = hd(resp.headers["content-type"])
    {:ok, %{content_type: content_type, data: resp_body}}
  end

  defp handle_response({:ok, resp}),
    do: return_error("Tile map service status: #{resp.status}")

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
