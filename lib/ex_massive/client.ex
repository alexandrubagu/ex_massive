defmodule ExMassive.Client do
  @moduledoc """
  HTTP client adapter for making requests to the Massive API.
  """

  @base_url "https://api.massive.com"

  @doc """
  Creates a new Tesla client with Bearer authentication.
  """
  def new(opts \\ []) do
    api_key = opts[:api_key] || Application.get_env(:ex_massive, :api_key)
    base_url = opts[:base_url] || Application.get_env(:ex_massive, :base_url, @base_url)

    # Use Tesla.Mock in test environment, Hackney otherwise
    adapter =
      case Application.get_env(:ex_massive, :adapter) do
        Tesla.Mock -> Tesla.Mock
        _ -> {Tesla.Adapter.Hackney, [recv_timeout: 30_000]}
      end

    middleware = [
      {Tesla.Middleware.BaseUrl, base_url},
      {Tesla.Middleware.Headers, [{"authorization", "Bearer #{api_key}"}]},
      Tesla.Middleware.JSON
    ]

    Tesla.client(middleware, adapter)
  end

  @doc """
  Makes a GET request to the specified path.
  """
  def get(path, opts \\ []) do
    client = new(opts)
    query = Keyword.get(opts, :query, [])
    Tesla.get(client, path, query: query)
  end
end
