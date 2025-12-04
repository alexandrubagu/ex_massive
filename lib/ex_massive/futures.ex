defmodule ExMassive.Futures do
  @moduledoc """
  Futures API endpoints for retrieving futures contract data.
  """

  def get_contract(client, futures_ticker, opts \\ []) do
    query = build_query(opts, [:date])
    Tesla.get(client, "/v3/reference/futures/contracts/#{futures_ticker}", query: query)
  end

  def list_contracts(client, opts \\ []) do
    query = build_query(opts, [:underlying_ticker, :expiration_date, :limit])
    Tesla.get(client, "/v3/reference/futures/contracts", query: query)
  end

  def get_aggregates(client, futures_ticker, multiplier, timespan, from, to, opts \\ []) do
    query = build_query(opts, [:adjusted, :sort, :limit])
    path = "/v2/aggs/ticker/#{futures_ticker}/range/#{multiplier}/#{timespan}/#{from}/#{to}"
    Tesla.get(client, path, query: query)
  end

  def get_previous_close(client, futures_ticker, opts \\ []) do
    query = build_query(opts, [:adjusted])
    Tesla.get(client, "/v2/aggs/ticker/#{futures_ticker}/prev", query: query)
  end

  def get_snapshot(client, futures_ticker) do
    Tesla.get(client, "/v3/snapshot/futures/#{futures_ticker}")
  end

  def get_last_trade(client, futures_ticker) do
    Tesla.get(client, "/v2/last/trade/#{futures_ticker}")
  end

  defp build_query(opts, allowed_keys) do
    opts
    |> Keyword.take(allowed_keys)
    |> Enum.filter(fn {_k, v} -> not is_nil(v) end)
  end
end
