defmodule ExMassive.FlatFiles do
  @moduledoc """
  Flat Files client for accessing historical bulk data files from Massive.com.

  Flat Files provide bulk access to historical market data stored in S3-compatible
  storage. Files are organized by date and asset class, available in CSV and JSON formats.

  ## Configuration

  Configure your S3 credentials:

      config :ex_massive,
        s3_access_key_id: "your_access_key",
        s3_secret_access_key: "your_secret_key",
        s3_region: "us-east-1",
        s3_bucket: "flatfiles.massive.com"

  ## Usage

      # List available files for a date range
      {:ok, files} = ExMassive.FlatFiles.list_files(
        asset_class: "stocks",
        data_type: "trades",
        date: "2024-01-15"
      )

      # Download a specific file
      {:ok, content} = ExMassive.FlatFiles.download_file(
        "stocks/trades/2024/01/15/trades.csv.gz"
      )

      # Download and parse CSV
      {:ok, data} = ExMassive.FlatFiles.get_trades(
        date: "2024-01-15",
        ticker: "AAPL"
      )

  ## Available Data Types

  ### Stocks
  - `trades` - Individual trade records
  - `quotes` - Bid/ask quotes
  - `aggregates` - OHLC bars (minute, daily)
  - `snapshots` - End-of-day snapshots

  ### Options, Futures, Forex, Crypto
  Similar data types available for each asset class.

  ## File Naming Convention

  Files are organized in S3 with the following pattern:
  `{asset_class}/{data_type}/{year}/{month}/{day}/{filename}.{format}.gz`

  Example: `stocks/trades/2024/01/15/trades.csv.gz`
  """

  @bucket "flatfiles.massive.com"

  @doc """
  Lists available files for the given criteria.

  ## Options
    * `:asset_class` - Asset class (stocks, options, futures, forex, crypto)
    * `:data_type` - Data type (trades, quotes, aggregates, snapshots)
    * `:date` - Date in "YYYY-MM-DD" format
    * `:prefix` - Custom S3 prefix to filter files
    * `:max_keys` - Maximum number of files to return (default: 1000)

  ## Examples

      # List all stock trades for a specific date
      {:ok, files} = ExMassive.FlatFiles.list_files(
        asset_class: "stocks",
        data_type: "trades",
        date: "2024-01-15"
      )

      # List with custom prefix
      {:ok, files} = ExMassive.FlatFiles.list_files(
        prefix: "stocks/trades/2024/01/"
      )
  """
  def list_files(opts \\ []) do
    prefix = build_prefix(opts)
    max_keys = Keyword.get(opts, :max_keys, 1000)

    bucket = get_bucket()

    ExAws.S3.list_objects_v2(bucket, prefix: prefix, max_keys: max_keys)
    |> ExAws.request(aws_config())
    |> case do
      {:ok, %{body: %{contents: contents}}} ->
        files = Enum.map(contents, fn item ->
          %{
            key: item.key,
            size: item.size,
            last_modified: item.last_modified,
            etag: item.etag
          }
        end)
        {:ok, files}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Downloads a file from S3.

  ## Parameters
    * `key` - S3 object key (path to file)

  ## Examples

      {:ok, content} = ExMassive.FlatFiles.download_file(
        "stocks/trades/2024/01/15/trades.csv.gz"
      )
  """
  def download_file(key) do
    bucket = get_bucket()

    ExAws.S3.get_object(bucket, key)
    |> ExAws.request(aws_config())
    |> case do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Downloads and decompresses a gzipped file.

  ## Parameters
    * `key` - S3 object key (path to file)

  ## Examples

      {:ok, content} = ExMassive.FlatFiles.download_and_decompress(
        "stocks/trades/2024/01/15/trades.csv.gz"
      )
  """
  def download_and_decompress(key) do
    case download_file(key) do
      {:ok, compressed_data} ->
        try do
          decompressed = :zlib.gunzip(compressed_data)
          {:ok, decompressed}
        rescue
          _ -> {:error, :decompression_failed}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Gets the presigned URL for a file (valid for 1 hour).

  ## Parameters
    * `key` - S3 object key (path to file)
    * `opts` - Options
      * `:expires_in` - Expiration time in seconds (default: 3600)

  ## Examples

      {:ok, url} = ExMassive.FlatFiles.get_presigned_url(
        "stocks/trades/2024/01/15/trades.csv.gz"
      )
  """
  def get_presigned_url(key, opts \\ []) do
    bucket = get_bucket()
    expires_in = Keyword.get(opts, :expires_in, 3600)

    config =
      aws_config()
      |> Enum.into(%{})

    ExAws.S3.presigned_url(config, :get, bucket, key, expires_in: expires_in)
  end

  @doc """
  Streams file content from S3 in chunks.

  ## Parameters
    * `key` - S3 object key (path to file)
    * `chunk_size` - Size of each chunk in bytes (default: 1MB)

  ## Examples

      ExMassive.FlatFiles.stream_file("stocks/trades/2024/01/15/trades.csv.gz")
      |> Stream.each(fn chunk -> IO.write(chunk) end)
      |> Stream.run()
  """
  def stream_file(key, chunk_size \\ 1_048_576) do
    bucket = get_bucket()

    ExAws.S3.download_file(bucket, key, :memory, chunk_size: chunk_size)
    |> ExAws.stream!(aws_config())
  end

  # Private functions

  defp build_prefix(opts) do
    cond do
      opts[:prefix] ->
        opts[:prefix]

      opts[:asset_class] && opts[:data_type] && opts[:date] ->
        date = Date.from_iso8601!(opts[:date])
        year = String.pad_leading("#{date.year}", 4, "0")
        month = String.pad_leading("#{date.month}", 2, "0")
        day = String.pad_leading("#{date.day}", 2, "0")

        "#{opts[:asset_class]}/#{opts[:data_type]}/#{year}/#{month}/#{day}/"

      opts[:asset_class] && opts[:data_type] ->
        "#{opts[:asset_class]}/#{opts[:data_type]}/"

      opts[:asset_class] ->
        "#{opts[:asset_class]}/"

      true ->
        ""
    end
  end

  defp get_bucket do
    Application.get_env(:ex_massive, :s3_bucket, @bucket)
  end

  defp aws_config do
    access_key_id = Application.get_env(:ex_massive, :s3_access_key_id)
    secret_access_key = Application.get_env(:ex_massive, :s3_secret_access_key)
    region = Application.get_env(:ex_massive, :s3_region, "us-east-1")

    [
      access_key_id: access_key_id,
      secret_access_key: secret_access_key,
      region: region,
      json_codec: Jason
    ]
  end
end
