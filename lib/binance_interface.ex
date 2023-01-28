defmodule BinanceInterface do
  alias BinanceInterface.Env
  alias BinanceInterface.Streamer

  import BinanceInterface.Request

  def stream_trades(base_asset, quote_asset) do
    # btcusdt
    symbol = symbol_name(base_asset, quote_asset)

    {:ok, _pid} = Streamer.connect("wss://stream.binance.com:9443/ws/#{symbol}@trade")
  end

  def asset(name), do: do_assets(name)

  def assets(), do: do_assets()

  defp do_assets(name \\ nil) do
    request =
      new_request(Env.base_url(), "/sapi/v3/asset/getUserAsset", Env.api_key())
      |> add_header("Content-Type", "application/x-www-form-urlencoded")
      |> maybe_add_body_data("asset", name)
      |> add_signature(Env.secret_key())

    {:ok, response} =
      Finch.build(:post, url(request), headers(request), body(request))
      |> Finch.request(MyFinch)

    response
    |> Map.fetch!(:body)
    |> Jason.decode!()
  end

  defp symbol_name(base_asset, quote_asset) do
    asset_name(base_asset) <> asset_name(quote_asset)
  end

  defp asset_name(asset) do
    asset
    |> to_string()
    |> String.downcase()
  end
end
