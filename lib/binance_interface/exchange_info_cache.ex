defmodule BinanceInterface.ExchangeInfoCache do
  use GenServer

  require Logger

  import BinanceInterface.Normalizer

  def tick_size(base_currency, quote_currency) do
    currency_pair = currency_pair(base_currency, quote_currency, :upcase)

    [{^currency_pair, data}] = :ets.lookup(:exchange_info, currency_pair)

    data["filters"]
    |> Enum.find(& &1["filterType"] == "PRICE_FILTER")
    |> Map.fetch!("tickSize")
  end

  def start_link(_state) do
    GenServer.start_link(__MODULE__, nil, name: :exchange_info)
  end

  @impl true
  def init(nil) do
    :ets.new(:exchange_info, [:named_table])

    response = BinanceInterface.exchange_info()

    response["symbols"]
    |> Enum.each(&:ets.insert(:exchange_info, {&1["symbol"], &1}))

    {:ok, nil}
  end
end
