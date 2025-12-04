defmodule ExMassive.Forex do
  @moduledoc """
  Forex API endpoints for retrieving foreign exchange data.
  """

  def get_ticker(client, ticker, opts \\ []) do
    query = build_query(opts, [:date])
    Tesla.get(client, "/v3/reference/tickers/#{ticker}", query: query)
  end

  def list_tickers(client, opts \\ []) do
    query = build_query(opts, [:limit, :sort, :order])
    Tesla.get(client, "/v3/reference/tickers", query: query)
  end

  def convert_currency(client, from, to, opts \\ []) do
    query = build_query(opts, [:amount, :precision])
    Tesla.get(client, "/v1/conversion/#{from}/#{to}", query: query)
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
    Tesla.get(client, "/v2/snapshot/locale/global/markets/forex/tickers/#{ticker}")
  end

  def get_last_quote(client, from, to) do
    Tesla.get(client, "/v1/last_quote/currencies/#{from}/#{to}")
  end

  defp build_query(opts, allowed_keys) do
    opts
    |> Keyword.take(allowed_keys)
    |> Enum.filter(fn {_k, v} -> not is_nil(v) end)
  end
end
