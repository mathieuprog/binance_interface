defmodule BinanceInterface.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :binance_interface,
      elixir: "~> 1.12",
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,

      # Hex
      version: @version,
      package: package(),
      description: "Binance API for Elixir",

      # ExDoc
      name: "Binance Interface",
      source_url: "https://github.com/mathieuprog/binance_interface",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {BinanceInterface.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.13.0"},
      {:mint_web_socket, "~> 1.0"},
      # TODO: once we support OTP 25+ only, castore might not be needed
      {:castore, "~> 0.1.18"},
      {:jason, "~> 1.4"},
      {:phoenix_pubsub, "~> 2.1"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      licenses: ["Apache-2.0"],
      maintainers: ["Mathieu Decaffmeyer"],
      links: %{
        "GitHub" => "https://github.com/mathieuprog/binance_interface",
        "Sponsor" => "https://github.com/sponsors/mathieuprog"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}"
    ]
  end
end
