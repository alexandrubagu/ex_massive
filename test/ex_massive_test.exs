defmodule ExMassiveTest do
  use ExUnit.Case
  doctest ExMassive

  import Tesla.Mock

  describe "client/1" do
    test "creates a client" do
      client = ExMassive.client()
      assert %Tesla.Client{} = client
    end

    test "creates a client with API key from options" do
      client = ExMassive.client(api_key: "custom_key")
      assert %Tesla.Client{} = client
    end

    test "client includes Bearer authorization header" do
      client = ExMassive.client(api_key: "test_key_123")

      mock(fn
        %{method: :get, url: "https://api.massive.com/test", headers: headers} ->
          auth_header = Enum.find(headers, fn {key, _} -> key == "authorization" end)
          assert auth_header == {"authorization", "Bearer test_key_123"}
          %Tesla.Env{status: 200, body: %{"status" => "ok"}}
      end)

      Tesla.get(client, "/test")
    end
  end
end
