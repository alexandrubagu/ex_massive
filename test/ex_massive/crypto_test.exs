defmodule ExMassive.CryptoTest do
  use ExUnit.Case
  import Tesla.Mock

  alias ExMassive.Crypto

  setup do
    client = ExMassive.client()
    {:ok, client: client}
  end

  describe "get_ticker/3" do
    test "fetches crypto ticker details", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v3/reference/tickers/X:BTCUSD"} ->
          json(%{
            "status" => "OK",
            "results" => %{
              "ticker" => "X:BTCUSD",
              "name" => "Bitcoin - United States Dollar",
              "market" => "crypto"
            }
          })
      end)

      assert {:ok, %Tesla.Env{status: 200, body: body}} = Crypto.get_ticker(client, "X:BTCUSD")
      assert body["results"]["ticker"] == "X:BTCUSD"
    end
  end

  describe "get_aggregates/7" do
    test "fetches crypto aggregate bars", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v2/aggs/ticker/X:BTCUSD/range/1/day/2023-01-01/2023-12-31"} ->
          json(%{
            "status" => "OK",
            "results" => [
              %{"o" => 42000.0, "h" => 43000.0, "l" => 41000.0, "c" => 42500.0}
            ]
          })
      end)

      assert {:ok, %Tesla.Env{status: 200}} =
               Crypto.get_aggregates(client, "X:BTCUSD", 1, "day", "2023-01-01", "2023-12-31")
    end
  end

  describe "get_snapshot/2" do
    test "fetches crypto snapshot", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v2/snapshot/locale/global/markets/crypto/tickers/X:BTCUSD"} ->
          json(%{
            "status" => "OK",
            "ticker" => %{"ticker" => "X:BTCUSD", "day" => %{"c" => 42500.0}}
          })
      end)

      assert {:ok, %Tesla.Env{status: 200}} = Crypto.get_snapshot(client, "X:BTCUSD")
    end
  end

  describe "get_last_trade/3" do
    test "fetches last crypto trade", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v1/last/crypto/BTC/USD"} ->
          json(%{
            "status" => "OK",
            "last" => %{"price" => 42500.0}
          })
      end)

      assert {:ok, %Tesla.Env{status: 200}} = Crypto.get_last_trade(client, "BTC", "USD")
    end
  end
end
