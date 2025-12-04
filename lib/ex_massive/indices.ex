defmodule ExMassive.Indices do
  @moduledoc """
  Indices API endpoints for retrieving market indices data.
  """

  def get_ticker(client, ticker, opts \\ []) do
    query = build_query(opts, [:date])
    Tesla.get(client, "/v3/reference/tickers/#{ticker}", query: query)
  end

  def list_indices(client, opts \\ []) do
    query = build_query(opts, [:limit, :sort, :order])
    Tesla.get(client, "/v3/reference/tickers", query: query)
  end

  def get_aggregates(client, ticker, multiplier, timespan, from, to, opts \\ []) do
    query = build_query(opts, [:adjusted, :sort, :limit])
    path = "/v2/aggs/ticker/#{ticker}/range/#{multiplier}/#{timespan}/#{from}/#{to}"
    Tesla.get(client, path, query: query)
  end

  def get_previous_close(client, ticker, opts \\ []) do
    query = build_query(opts, [:adjusted])
    Tesla.get(client, "/v2/aggs/ticker/#{ticker}/prev", query: query)
  end

  def get_snapshot(client, ticker) do
    Tesla.get(client, "/v3/snapshot/indices/#{ticker}")
  end

  defp build_query(opts, allowed_keys) do
    opts
    |> Keyword.take(allowed_keys)
    |> Enum.filter(fn {_k, v} -> not is_nil(v) end)
  end
end
