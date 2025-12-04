defmodule ExMassive.Stocks do
  @moduledoc """
  Stocks API endpoints for retrieving stock market data.
  """

  @doc """
  Get details for a specific ticker.
  """
  def get_ticker(client, ticker, opts \\ []) do
    query = build_query(opts, [:date])
    Tesla.get(client, "/v3/reference/tickers/#{ticker}", query: query)
  end

  @doc """
  Get all available stock tickers.
  """
  def list_tickers(client, opts \\ []) do
    query = build_query(opts, [:limit, :sort, :order])
    Tesla.get(client, "/v3/reference/tickers", query: query)
  end

  @doc """
  Get aggregate bars (OHLC) for a stock over a given date range.
  """
  def get_aggregates(client, ticker, multiplier, timespan, from, to, opts \\ []) do
    query = build_query(opts, [:adjusted, :sort, :limit])
    path = "/v2/aggs/ticker/#{ticker}/range/#{multiplier}/#{timespan}/#{from}/#{to}"
    Tesla.get(client, path, query: query)
  end

  @doc """
  Get the previous day's open, high, low, and close for a ticker.
  """
  def get_previous_close(client, ticker, opts \\ []) do
    query = build_query(opts, [:adjusted])
    Tesla.get(client, "/v2/aggs/ticker/#{ticker}/prev", query: query)
  end

  @doc """
  Get the last trade for a ticker.
  """
  def get_last_trade(client, ticker) do
    Tesla.get(client, "/v2/last/trade/#{ticker}")
  end

  @doc """
  Get the last quote for a ticker.
  """
  def get_last_quote(client, ticker) do
    Tesla.get(client, "/v2/last/nbbo/#{ticker}")
  end

  @doc """
  Get the snapshot for a single ticker.
  """
  def get_snapshot(client, ticker) do
    Tesla.get(client, "/v2/snapshot/locale/us/markets/stocks/tickers/#{ticker}")
  end

  @doc """
  Get snapshots for all tickers.
  """
  def get_all_snapshots(client, opts \\ []) do
    query = build_query(opts, [:tickers])
    Tesla.get(client, "/v2/snapshot/locale/us/markets/stocks/tickers", query: query)
  end

  @doc """
  Get Simple Moving Average (SMA) for a ticker.
  """
  def get_sma(client, ticker, opts \\ []) do
    query = build_query(opts, [:timestamp, :timespan, :adjusted, :window, :series_type])
    Tesla.get(client, "/v1/indicators/sma/#{ticker}", query: query)
  end

  @doc """
  Get Exponential Moving Average (EMA) for a ticker.
  """
  def get_ema(client, ticker, opts \\ []) do
    query = build_query(opts, [:timestamp, :timespan, :adjusted, :window, :series_type])
    Tesla.get(client, "/v1/indicators/ema/#{ticker}", query: query)
  end

  @doc """
  Get MACD (Moving Average Convergence Divergence) for a ticker.
  """
  def get_macd(client, ticker, opts \\ []) do
    query = build_query(opts, [:timestamp, :timespan, :adjusted, :short_window, :long_window, :signal_window, :series_type])
    Tesla.get(client, "/v1/indicators/macd/#{ticker}", query: query)
  end

  @doc """
  Get RSI (Relative Strength Index) for a ticker.
  """
  def get_rsi(client, ticker, opts \\ []) do
    query = build_query(opts, [:timestamp, :timespan, :adjusted, :window, :series_type])
    Tesla.get(client, "/v1/indicators/rsi/#{ticker}", query: query)
  end

  defp build_query(opts, allowed_keys) do
    opts
    |> Keyword.take(allowed_keys)
    |> Enum.filter(fn {_k, v} -> not is_nil(v) end)
  end
end
