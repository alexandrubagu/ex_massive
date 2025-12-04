defmodule ExMassive.Options do
  @moduledoc """
  Options API endpoints for retrieving options contract data.
  """

  def get_contract(client, options_ticker, opts \\ []) do
    query = build_query(opts, [:date])
    Tesla.get(client, "/v3/reference/options/contracts/#{options_ticker}", query: query)
  end

  def list_contracts(client, opts \\ []) do
    query = build_query(opts, [:underlying_ticker, :expiration_date, :strike_price, :contract_type, :limit])
    Tesla.get(client, "/v3/reference/options/contracts", query: query)
  end

  def get_aggregates(client, options_ticker, multiplier, timespan, from, to, opts \\ []) do
    query = build_query(opts, [:adjusted, :sort, :limit])
    path = "/v2/aggs/ticker/#{options_ticker}/range/#{multiplier}/#{timespan}/#{from}/#{to}"
    Tesla.get(client, path, query: query)
  end

  def get_previous_close(client, options_ticker, opts \\ []) do
    query = build_query(opts, [:adjusted])
    Tesla.get(client, "/v2/aggs/ticker/#{options_ticker}/prev", query: query)
  end

  def get_snapshot(client, options_ticker) do
    Tesla.get(client, "/v3/snapshot/options/#{options_ticker}")
  end

  def get_option_chain(client, underlying_ticker, opts \\ []) do
    query = build_query(opts, [:strike_price, :expiration_date, :contract_type])
    Tesla.get(client, "/v3/snapshot/options/#{underlying_ticker}", query: query)
  end

  def get_last_trade(client, options_ticker) do
    Tesla.get(client, "/v2/last/trade/#{options_ticker}")
  end

  defp build_query(opts, allowed_keys) do
    opts
    |> Keyword.take(allowed_keys)
    |> Enum.filter(fn {_k, v} -> not is_nil(v) end)
  end
end
