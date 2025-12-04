defmodule ExMassive.StocksTest do
  use ExUnit.Case
  import Tesla.Mock

  alias ExMassive.Stocks

  setup do
    client = ExMassive.client()
    {:ok, client: client}
  end

  describe "get_ticker/3" do
    test "fetches ticker details", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v3/reference/tickers/AAPL"} ->
          json(%{
            "status" => "OK",
            "results" => %{
              "ticker" => "AAPL",
              "name" => "Apple Inc.",
              "market" => "stocks"
            }
          })
      end)

      assert {:ok, %Tesla.Env{status: 200, body: body}} = Stocks.get_ticker(client, "AAPL")
      assert body["results"]["ticker"] == "AAPL"
    end

    test "fetches ticker with date parameter", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v3/reference/tickers/AAPL", query: query} ->
          assert query[:date] == "2023-01-01"
          json(%{"status" => "OK", "results" => %{"ticker" => "AAPL"}})
      end)

      Stocks.get_ticker(client, "AAPL", date: "2023-01-01")
    end
  end

  describe "list_tickers/2" do
    test "lists all tickers", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v3/reference/tickers"} ->
          json(%{
            "status" => "OK",
            "results" => [
              %{"ticker" => "AAPL"},
              %{"ticker" => "GOOGL"}
            ]
          })
      end)

      assert {:ok, %Tesla.Env{status: 200}} = Stocks.list_tickers(client)
    end

    test "lists tickers with limit", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v3/reference/tickers", query: query} ->
          assert query[:limit] == 10
          json(%{"status" => "OK", "results" => []})
      end)

      Stocks.list_tickers(client, limit: 10)
    end
  end

  describe "get_aggregates/7" do
    test "fetches aggregate bars", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v2/aggs/ticker/AAPL/range/1/day/2023-01-01/2023-12-31"} ->
          json(%{
            "status" => "OK",
            "results" => [
              %{"o" => 150.0, "h" => 155.0, "l" => 149.0, "c" => 154.0, "v" => 1000000}
            ]
          })
      end)

      assert {:ok, %Tesla.Env{status: 200, body: body}} =
               Stocks.get_aggregates(client, "AAPL", 1, "day", "2023-01-01", "2023-12-31")

      assert length(body["results"]) == 1
    end

    test "fetches aggregates with optional parameters", %{client: client} do
      mock(fn
        %{
          method: :get,
          url: "https://api.massive.com/v2/aggs/ticker/AAPL/range/1/day/2023-01-01/2023-12-31",
          query: query
        } ->
          assert query[:adjusted] == true
          assert query[:sort] == "asc"
          assert query[:limit] == 5000
          json(%{"status" => "OK", "results" => []})
      end)

      Stocks.get_aggregates(client, "AAPL", 1, "day", "2023-01-01", "2023-12-31",
        adjusted: true,
        sort: "asc",
        limit: 5000
      )
    end
  end

  describe "get_previous_close/3" do
    test "fetches previous day close", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v2/aggs/ticker/AAPL/prev"} ->
          json(%{
            "status" => "OK",
            "results" => %{"o" => 150.0, "c" => 154.0}
          })
      end)

      assert {:ok, %Tesla.Env{status: 200}} = Stocks.get_previous_close(client, "AAPL")
    end
  end

  describe "get_last_trade/2" do
    test "fetches last trade", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v2/last/trade/AAPL"} ->
          json(%{
            "status" => "OK",
            "results" => %{"p" => 154.0, "s" => 100}
          })
      end)

      assert {:ok, %Tesla.Env{status: 200}} = Stocks.get_last_trade(client, "AAPL")
    end
  end

  describe "get_last_quote/2" do
    test "fetches last quote", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v2/last/nbbo/AAPL"} ->
          json(%{
            "status" => "OK",
            "results" => %{"P" => 154.0, "p" => 153.98}
          })
      end)

      assert {:ok, %Tesla.Env{status: 200}} = Stocks.get_last_quote(client, "AAPL")
    end
  end

  describe "get_snapshot/2" do
    test "fetches snapshot", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v2/snapshot/locale/us/markets/stocks/tickers/AAPL"} ->
          json(%{
            "status" => "OK",
            "ticker" => %{"ticker" => "AAPL", "day" => %{"c" => 154.0}}
          })
      end)

      assert {:ok, %Tesla.Env{status: 200}} = Stocks.get_snapshot(client, "AAPL")
    end
  end

  describe "get_sma/3" do
    test "fetches SMA", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v1/indicators/sma/AAPL"} ->
          json(%{
            "status" => "OK",
            "results" => %{"values" => [%{"value" => 150.0}]}
          })
      end)

      assert {:ok, %Tesla.Env{status: 200}} = Stocks.get_sma(client, "AAPL")
    end

    test "fetches SMA with parameters", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v1/indicators/sma/AAPL", query: query} ->
          assert query[:window] == 50
          assert query[:timespan] == "day"
          json(%{"status" => "OK", "results" => %{}})
      end)

      Stocks.get_sma(client, "AAPL", window: 50, timespan: "day")
    end
  end

  describe "get_ema/3" do
    test "fetches EMA", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v1/indicators/ema/AAPL"} ->
          json(%{"status" => "OK", "results" => %{}})
      end)

      assert {:ok, %Tesla.Env{status: 200}} = Stocks.get_ema(client, "AAPL")
    end
  end

  describe "get_macd/3" do
    test "fetches MACD", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v1/indicators/macd/AAPL"} ->
          json(%{"status" => "OK", "results" => %{}})
      end)

      assert {:ok, %Tesla.Env{status: 200}} = Stocks.get_macd(client, "AAPL")
    end
  end

  describe "get_rsi/3" do
    test "fetches RSI", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v1/indicators/rsi/AAPL"} ->
          json(%{"status" => "OK", "results" => %{}})
      end)

      assert {:ok, %Tesla.Env{status: 200}} = Stocks.get_rsi(client, "AAPL")
    end
  end
end
