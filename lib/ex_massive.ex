defmodule ExMassive do
  @moduledoc """
  ExMassive - Elixir SDK for Massive.com financial data API.

  ## Configuration

  Configure your API key in your config file:

      config :ex_massive,
        api_key: "your_api_key_here"

  ## Usage

      # Get a client instance
      client = ExMassive.client()

      # Or pass options directly
      client = ExMassive.client(api_key: "your_key")

      # Use the client with various modules
      ExMassive.Stocks.get_ticker(client, "AAPL")
      ExMassive.Crypto.get_ticker(client, "X:BTCUSD")
  """

  @doc """
  Creates a new REST client with Bearer authentication.

  ## Options

    * `:api_key` - Your Massive.com API key
    * `:base_url` - Base URL for the API (default: "https://api.massive.com")

  ## Examples

      iex> client = ExMassive.client()
      iex> match?(%Tesla.Client{}, client)
      true

  """
  def client(opts \\ []) do
    ExMassive.RestClient.new(opts)
  end
end
