defmodule BinanceInterface do
  alias BinanceInterface.Env
  alias BinanceInterface.Streamer

  import BinanceInterface.Normalizer
  import BinanceInterface.Request

  def stream_trades(base_currency, quote_currency) do
    currency_pair = currency_pair(base_currency, quote_currency, :downcase)

    {:ok, _pid} = Streamer.connect("wss://stream.binance.com:9443/ws/#{currency_pair}@trade")
  end

  def asset(currency), do: do_assets(currency)

  def positive_assets(), do: do_assets()

  defp do_assets(currency \\ nil) do
    maybe_currency = maybe_currency(currency, :upcase)

    request =
      new_request(Env.base_url(), "/sapi/v3/asset/getUserAsset", Env.api_key())
      |> add_header("Content-Type", "application/x-www-form-urlencoded")
      |> maybe_add_body_data("asset", maybe_currency)
      |> add_signature(Env.secret_key())

    {:ok, response} =
      Finch.build(:post, url(request), headers(request), body(request))
      |> Finch.request(BinanceInterface.Finch)

    response
    |> Map.fetch!(:body)
    |> Jason.decode!()
  end

  def exchange_info(), do: do_exchange_info()

  def exchange_info(base_currency, quote_currency) do
    currency_pair = currency_pair(base_currency, quote_currency, :upcase)

    do_exchange_info(currency_pair)
  end

  def do_exchange_info(currency_pair \\ nil) do
    request =
      new_request("https://data.binance.com", "/api/v3/exchangeInfo")
      |> maybe_add_body_data("symbol", currency_pair)

    {:ok, response} =
      Finch.build(:get, url(request), headers(request), body(request))
      |> Finch.request(BinanceInterface.Finch, receive_timeout: 600_000)

    response
    |> Map.fetch!(:body)
    |> Jason.decode!()
  end
end
