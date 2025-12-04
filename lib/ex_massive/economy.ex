defmodule ExMassive.Economy do
  @moduledoc """
  Economy API endpoints for retrieving economic data.
  """

  def get_treasury_yields(client, opts \\ []) do
    query = build_query(opts, [:date, :yield_curve])
    Tesla.get(client, "/v1/indicators/treasury/yields", query: query)
  end

  def get_inflation_data(client, indicator, opts \\ []) do
    query = build_query(opts, [:date, :start_date, :end_date])
    Tesla.get(client, "/v1/indicators/inflation/#{indicator}", query: query)
  end

  def get_inflation_expectations(client, opts \\ []) do
    query = build_query(opts, [:date, :start_date, :end_date])
    Tesla.get(client, "/v1/indicators/inflation/expectations", query: query)
  end

  defp build_query(opts, allowed_keys) do
    opts
    |> Keyword.take(allowed_keys)
    |> Enum.filter(fn {_k, v} -> not is_nil(v) end)
  end
end
