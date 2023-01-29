defmodule BinanceInterface.Normalizer do
  def currency_pair(base_currency, quote_currency, :upcase) do
    currency(base_currency, :upcase) <> currency(quote_currency, :upcase)
  end

  def currency_pair(base_currency, quote_currency, :downcase) do
    currency(base_currency, :downcase) <> currency(quote_currency, :downcase)
  end

  def currency(currency, :upcase) do
    currency
    |> to_string()
    |> String.upcase()
  end

  def currency(currency, :downcase) do
    currency
    |> to_string()
    |> String.downcase()
  end

  def maybe_currency(nil, _case), do: nil

  def maybe_currency(currency, case_), do: currency(currency, case_)
end
