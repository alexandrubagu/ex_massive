defmodule ExMassive.OptionsTest do
  use ExUnit.Case
  import Tesla.Mock

  alias ExMassive.Options

  setup do
    client = ExMassive.client()
    {:ok, client: client}
  end

  describe "get_contract/3" do
    test "fetches options contract details", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v3/reference/options/contracts/O:AAPL230616C00150000"} ->
          json(%{
            "status" => "OK",
            "results" => %{
              "ticker" => "O:AAPL230616C00150000",
              "underlying_ticker" => "AAPL",
              "strike_price" => 150.0,
              "expiration_date" => "2023-06-16"
            }
          })
      end)

      assert {:ok, %Tesla.Env{status: 200, body: body}} =
               Options.get_contract(client, "O:AAPL230616C00150000")

      assert body["results"]["underlying_ticker"] == "AAPL"
    end
  end

  describe "list_contracts/2" do
    test "lists options contracts", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v3/reference/options/contracts"} ->
          json(%{
            "status" => "OK",
            "results" => [
              %{"ticker" => "O:AAPL230616C00150000"},
              %{"ticker" => "O:AAPL230616P00150000"}
            ]
          })
      end)

      assert {:ok, %Tesla.Env{status: 200}} = Options.list_contracts(client)
    end

    test "lists contracts with filters", %{client: client} do
      mock(fn
        %{
          method: :get,
          url: "https://api.massive.com/v3/reference/options/contracts",
          query: query
        } ->
          assert query[:underlying_ticker] == "AAPL"
          assert query[:contract_type] == "call"
          json(%{"status" => "OK", "results" => []})
      end)

      Options.list_contracts(client, underlying_ticker: "AAPL", contract_type: "call")
    end
  end

  describe "get_option_chain/3" do
    test "fetches option chain for underlying", %{client: client} do
      mock(fn
        %{method: :get, url: "https://api.massive.com/v3/snapshot/options/AAPL"} ->
          json(%{
            "status" => "OK",
            "results" => [
              %{"ticker" => "O:AAPL230616C00150000", "strike" => 150.0}
            ]
          })
      end)

      assert {:ok, %Tesla.Env{status: 200}} = Options.get_option_chain(client, "AAPL")
    end
  end
end
