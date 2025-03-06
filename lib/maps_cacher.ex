defmodule MapsCacher do
  def fetch_tile(provider, type, z, x, y) do
    download_tile(provider, type, z, x, y)
  end

  defp has_cahced_tile(provider, type, z, x, y) do
  end

  defp get_from_cache(provider, type, z, x, y) do
  end

  defp resolve_type(provider, type) when provider == "google" do
    case type do
      "standart" -> "y"
    end
  end

  defp resolve_type(provider, type), do: type

  defp download_tile(provider, type, z, x, y) when provider == "google" do
    pattern = "https://mt1.google.com/vt/lyrs={type}&x={x}&y={y}&z={z}"

    request_url =
      pattern
      |> String.replace("{type}", resolve_type(provider, type))
      |> String.replace("{x}", x)
      |> String.replace("{y}", y)
      |> String.replace("{z}", z)

    headers = [
      user_agent:
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36",
      sec_ch_ua_platform: "Windows",
      sec_ch_ua_mobile: "?0",
      sec_ch_ua: "\"Not(A:Brand\";v=\"99\", \"Google Chrome\";v=\"133\"",
      upgrade_insecure_requests: "1"
    ]

    Req.get(request_url, headers: headers)
    |> handle_response
  end

  defp download_tile(provider, type, z, x, y) when provider == 'openstreetmaps' do
    raise RuntimeError, "MapsCacher.download_tile/5 is not implemented yet"
  end

  # Response handlers

  defp handle_response({:ok, resp}) when resp.status == 200 do
    resp_body = resp.body
    content_type = hd(resp.headers["content-type"])
    {:ok, %{content_type: content_type, data: resp_body}}
  end

  defp handle_response({:ok, resp}),
    do: return_error("Google maps service status: #{resp.status}")

  defp handle_response({:error, exception}) do
    {:error, {502, exception}}
  end

  defp handle_response(_) do
    {:error, {502, "Unknown error"}}
  end

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
