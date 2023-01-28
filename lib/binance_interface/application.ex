defmodule BinanceInterface.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: BinanceInterface.Finch},
      {
        Phoenix.PubSub,
        adapter_name: Phoenix.PubSub.PG2, name: BinanceInterface.PubSub
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BinanceInterface.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
