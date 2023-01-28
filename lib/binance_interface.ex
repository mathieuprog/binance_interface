defmodule BinanceInterface do
  alias BinanceInterface.Env
  alias BinanceInterface.Streamer

  import BinanceInterface.Request

  def stream_trades(base_currency, quote_currency) do
    currency_pair = currency_pair(base_currency, quote_currency)

    {:ok, _pid} = Streamer.connect("wss://stream.binance.com:9443/ws/#{currency_pair}@trade")
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
      |> Finch.request(BinanceInterface.Finch)

    response
    |> Map.fetch!(:body)
    |> Jason.decode!()
  end

  defp currency_pair(base_currency, quote_currency) do
    currency(base_currency) <> currency(quote_currency)
  end

  defp currency(currency) do
    currency
    |> to_string()
    |> String.downcase()
  end
end
