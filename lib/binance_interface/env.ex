defmodule BinanceInterface.Env do
  def put_api_key(api_key) do
    Process.put({__MODULE__, :api_key}, api_key)
  end

  def put_secret_key(secret_key) do
    Process.put({__MODULE__, :secret_key}, secret_key)
  end

  def put_base_url(base_url) do
    Process.put({__MODULE__, :base_url}, base_url)
  end

  def api_key() do
    Process.get({__MODULE__, :api_key}, Application.get_env(:binance_interface, :api_key)) ||
      raise "binance api key not found"
  end

  def secret_key() do
    Process.get({__MODULE__, :secret_key}, Application.get_env(:binance_interface, :secret_key)) ||
      raise "binance secret key not found"
  end

  def base_url() do
    Process.get(
      {__MODULE__, :base_url},
      Application.get_env(:binance_interface, :base_url, "https://api.binance.com")
    )
  end
end
