# ExMassive

Elixir SDK for the [Massive.com](https://massive.com) financial data API. Provides a simple and clean interface to access stocks, options, futures, indices, forex, crypto, and economic data.

## Features

- Simple, clean API design
- Bearer token authentication
- **REST API** - Comprehensive endpoint coverage:
  - Stocks (tickers, aggregates, trades, quotes, technical indicators, fundamentals)
  - Options (contracts, chains, aggregates)
  - Futures (contracts, aggregates)
  - Indices (tickers, aggregates)
  - Forex (tickers, conversion, aggregates)
  - Crypto (tickers, aggregates, trades)
  - Economy (treasury yields, inflation data)
- **WebSocket API** - Real-time data streaming:
  - Real-time and 15-minute delayed feeds
  - Subscribe to trades, quotes, and aggregates
  - Support for all asset classes
  - Automatic authentication and reconnection
- **Flat Files** - Bulk historical data access:
  - S3-based bulk data downloads
  - CSV and JSON formats
  - Compressed (gzip) files
  - Historical trades, quotes, aggregates
  - Presigned URLs for direct access
- Full test coverage with Tesla Mock
- Easy to test in your application using Tesla.Mock

## Installation

Add `ex_massive` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_massive, "~> 0.1.0"}
  ]
end
```

## Configuration

Configure your API key in `config/config.exs`:

```elixir
config :ex_massive,
  api_key: "your_api_key_here"
```

You can also pass the API key directly when creating a client:

```elixir
client = ExMassive.client(api_key: "your_api_key")
```

## Usage

### Basic Usage

```elixir
# Create a client
client = ExMassive.client()

# Get stock ticker information
{:ok, response} = ExMassive.Stocks.get_ticker(client, "AAPL")

# Get aggregate bars (OHLC data)
{:ok, response} = ExMassive.Stocks.get_aggregates(
  client,
  "AAPL",
  1,              # multiplier
  "day",          # timespan
  "2023-01-01",   # from
  "2023-12-31"    # to
)

# Get last trade
{:ok, response} = ExMassive.Stocks.get_last_trade(client, "AAPL")

# Get technical indicators
{:ok, response} = ExMassive.Stocks.get_sma(client, "AAPL", window: 50, timespan: "day")
{:ok, response} = ExMassive.Stocks.get_rsi(client, "AAPL", window: 14)
```

### Options

```elixir
# Get options contract details
{:ok, response} = ExMassive.Options.get_contract(client, "O:AAPL230616C00150000")

# List options contracts
{:ok, response} = ExMassive.Options.list_contracts(client,
  underlying_ticker: "AAPL",
  contract_type: "call"
)

# Get option chain
{:ok, response} = ExMassive.Options.get_option_chain(client, "AAPL")
```

### Crypto

```elixir
# Get crypto ticker
{:ok, response} = ExMassive.Crypto.get_ticker(client, "X:BTCUSD")

# Get crypto aggregates
{:ok, response} = ExMassive.Crypto.get_aggregates(
  client,
  "X:BTCUSD",
  1,
  "day",
  "2023-01-01",
  "2023-12-31"
)

# Get last trade
{:ok, response} = ExMassive.Crypto.get_last_trade(client, "BTC", "USD")
```

### Forex

```elixir
# Get forex ticker
{:ok, response} = ExMassive.Forex.get_ticker(client, "C:EURUSD")

# Convert currency
{:ok, response} = ExMassive.Forex.convert_currency(client, "USD", "EUR", amount: 100)

# Get forex aggregates
{:ok, response} = ExMassive.Forex.get_aggregates(
  client,
  "C:EURUSD",
  1,
  "day",
  "2023-01-01",
  "2023-12-31"
)
```

### Economy

```elixir
# Get treasury yields
{:ok, response} = ExMassive.Economy.get_treasury_yields(client)

# Get inflation data
{:ok, response} = ExMassive.Economy.get_inflation_data(client, "CPI")

# Get inflation expectations
{:ok, response} = ExMassive.Economy.get_inflation_expectations(client)
```

### Futures & Indices

```elixir
# Futures
{:ok, response} = ExMassive.Futures.get_contract(client, "ES")
{:ok, response} = ExMassive.Futures.list_contracts(client)

# Indices
{:ok, response} = ExMassive.Indices.get_ticker(client, "I:SPX")
{:ok, response} = ExMassive.Indices.get_aggregates(client, "I:SPX", 1, "day", "2023-01-01", "2023-12-31")
```

## WebSocket Streaming

### Basic Usage

```elixir
# Define a handler module
defmodule MyHandler do
  def handle_message(message, state) do
    IO.inspect(message, label: "Market Data")
    {:ok, state}
  end

  def handle_connect(state) do
    IO.puts("Connected to Massive WebSocket!")
    {:ok, state}
  end

  def handle_disconnect(reason, state) do
    IO.puts("Disconnected: #{inspect(reason)}")
    {:ok, state}
  end
end

# Start a WebSocket connection
{:ok, ws} = ExMassive.WebSocketClient.start_link(
  api_key: "your_api_key",
  handler: MyHandler,
  realtime: false  # Use 15-minute delayed feed (set true for real-time)
)

# Subscribe to channels
ExMassive.WebSocketClient.subscribe(ws, ["AM.AAPL", "AM.MSFT"])

# Subscribe to trades for a symbol
ExMassive.WebSocketClient.subscribe(ws, "T.GOOGL")

# Subscribe to all tickers for a channel type
ExMassive.WebSocketClient.subscribe(ws, "AM.*")

# Unsubscribe from channels
ExMassive.WebSocketClient.unsubscribe(ws, ["AM.AAPL"])

# Get current subscriptions
ExMassive.WebSocketClient.get_subscriptions(ws)
```

### Available WebSocket Channels

#### Stocks
- `AM.{ticker}` - Minute aggregates (OHLC per minute)
- `A.{ticker}` - Second aggregates (OHLC per second)
- `T.{ticker}` - Trades
- `Q.{ticker}` - Quotes

#### Using Wildcards
- `AM.*` - All stocks minute aggregates
- `T.*` - All stock trades
- `Q.AAPL` - Quotes for AAPL only

### Example: Processing Real-Time Trade Data

```elixir
defmodule TradeProcessor do
  def handle_message(%{"ev" => "T", "sym" => symbol, "p" => price, "s" => size}, state) do
    IO.puts("Trade: #{symbol} - Price: #{price}, Size: #{size}")
    # Process the trade...
    {:ok, state}
  end

  def handle_message(%{"ev" => "AM"} = aggregate, state) do
    # Handle minute aggregate
    IO.inspect(aggregate, label: "Minute Bar")
    {:ok, state}
  end

  def handle_message(message, state) do
    # Handle other message types
    {:ok, state}
  end

  def handle_connect(state), do: {:ok, state}
  def handle_disconnect(_reason, state), do: {:ok, state}
end

{:ok, ws} = ExMassive.WebSocketClient.start_link(
  api_key: "your_api_key",
  handler: TradeProcessor,
  handler_state: %{trades_count: 0},
  realtime: true
)

# Subscribe to trades and minute aggregates
ExMassive.WebSocketClient.subscribe(ws, ["T.AAPL", "T.MSFT", "AM.AAPL"])
```

## Flat Files (Bulk Data)

### Configuration

Configure your S3 credentials for Flat Files access:

```elixir
config :ex_massive,
  s3_access_key_id: "your_s3_access_key",
  s3_secret_access_key: "your_s3_secret_key",
  s3_region: "us-east-1",
  s3_bucket: "flatfiles.massive.com"
```

### Basic Usage

```elixir
# List available files for a specific date
{:ok, files} = ExMassive.FlatFiles.list_files(
  asset_class: "stocks",
  data_type: "trades",
  date: "2024-01-15"
)

# Download a file
{:ok, content} = ExMassive.FlatFiles.download_file(
  "stocks/trades/2024/01/15/trades.csv.gz"
)

# Download and decompress automatically
{:ok, csv_content} = ExMassive.FlatFiles.download_and_decompress(
  "stocks/trades/2024/01/15/trades.csv.gz"
)

# Get a presigned URL (valid for 1 hour)
{:ok, url} = ExMassive.FlatFiles.get_presigned_url(
  "stocks/trades/2024/01/15/trades.csv.gz"
)

# Stream large files
ExMassive.FlatFiles.stream_file("stocks/trades/2024/01/15/trades.csv.gz")
|> Stream.each(fn chunk -> process_chunk(chunk) end)
|> Stream.run()
```

### Available Data Types

Flat Files are organized by:
- **Asset Class**: `stocks`, `options`, `futures`, `forex`, `crypto`
- **Data Type**: `trades`, `quotes`, `aggregates`, `snapshots`
- **Date**: Organized by year/month/day

### File Naming Pattern

```
{asset_class}/{data_type}/{year}/{month}/{day}/{filename}.{format}.gz
```

Examples:
- `stocks/trades/2024/01/15/trades.csv.gz`
- `options/quotes/2024/01/15/quotes.json.gz`
- `crypto/aggregates/2024/01/15/minute_aggs.csv.gz`

### Listing Files

```elixir
# List all stock trades for January 2024
{:ok, files} = ExMassive.FlatFiles.list_files(
  asset_class: "stocks",
  data_type: "trades",
  prefix: "stocks/trades/2024/01/"
)

# List with custom prefix
{:ok, files} = ExMassive.FlatFiles.list_files(
  prefix: "stocks/",
  max_keys: 100
)

# Files include metadata
files
|> Enum.each(fn file ->
  IO.puts("File: #{file.key}")
  IO.puts("Size: #{file.size} bytes")
  IO.puts("Last Modified: #{file.last_modified}")
end)
```

### Downloading Files

```elixir
# Download compressed file
{:ok, compressed} = ExMassive.FlatFiles.download_file(
  "stocks/trades/2024/01/15/trades.csv.gz"
)

# Download and decompress
{:ok, csv_data} = ExMassive.FlatFiles.download_and_decompress(
  "stocks/trades/2024/01/15/trades.csv.gz"
)

# Parse CSV data
csv_data
|> String.split("\n")
|> CSV.decode(headers: true)
|> Enum.each(fn {:ok, row} ->
  IO.inspect(row)
end)
```

### Streaming Large Files

For large files, use streaming to avoid loading everything into memory:

```elixir
# Stream and process in chunks
ExMassive.FlatFiles.stream_file(
  "stocks/trades/2024/01/15/trades.csv.gz",
  1_048_576  # 1MB chunks
)
|> Stream.each(fn chunk ->
  # Process each chunk
  process_data(chunk)
end)
|> Stream.run()
```

## Testing

Run the test suite:

```bash
mix test
```

### Testing in Your Application

To enable mocking in your tests, configure Tesla.Mock in `config/test.exs`:

```elixir
config :ex_massive,
  adapter: Tesla.Mock
```

Then use Tesla.Mock to mock API calls in your tests:

```elixir
defmodule MyAppTest do
  use ExUnit.Case
  import Tesla.Mock

  test "fetch stock ticker" do
    # Create a client
    client = ExMassive.client(api_key: "test_key")

    # Mock the HTTP response
    mock(fn
      %{method: :get, url: "https://api.massive.com/v3/reference/tickers/AAPL"} ->
        json(%{"status" => "OK", "results" => %{"ticker" => "AAPL"}})
    end)

    # Make the API call
    assert {:ok, %Tesla.Env{body: body}} = ExMassive.Stocks.get_ticker(client, "AAPL")
    assert body["results"]["ticker"] == "AAPL"
  end
end
```

The library automatically uses Tesla.Mock when configured, so you can easily test your application without making real API calls.

## API Coverage

### Stocks
- `get_ticker/3` - Get ticker details
- `list_tickers/2` - List all tickers
- `get_aggregates/7` - Get OHLC aggregate bars
- `get_previous_close/3` - Get previous day data
- `get_last_trade/2` - Get last trade
- `get_last_quote/2` - Get last quote
- `get_snapshot/2` - Get ticker snapshot
- `get_all_snapshots/2` - Get all snapshots
- `get_sma/3` - Simple Moving Average
- `get_ema/3` - Exponential Moving Average
- `get_macd/3` - MACD indicator
- `get_rsi/3` - RSI indicator

### Options
- `get_contract/3` - Get contract details
- `list_contracts/2` - List contracts
- `get_aggregates/7` - Get contract aggregates
- `get_previous_close/3` - Get previous day data
- `get_snapshot/2` - Get contract snapshot
- `get_option_chain/3` - Get option chain
- `get_last_trade/2` - Get last trade

### Crypto
- `get_ticker/3` - Get crypto ticker details
- `list_tickers/2` - List all crypto tickers
- `get_aggregates/7` - Get OHLC aggregate bars
- `get_previous_close/3` - Get previous day data
- `get_snapshot/2` - Get crypto ticker snapshot
- `get_all_snapshots/2` - Get all crypto snapshots
- `get_last_trade/3` - Get last trade

### Forex
- `get_ticker/3` - Get forex pair details
- `list_tickers/2` - List all forex pairs
- `convert_currency/4` - Convert currency with real-time rates
- `get_aggregates/7` - Get OHLC aggregate bars
- `get_previous_close/3` - Get previous day data
- `get_snapshot/2` - Get forex pair snapshot
- `get_last_quote/3` - Get last quote

### Futures
- `get_contract/3` - Get futures contract details
- `list_contracts/2` - List futures contracts
- `get_aggregates/7` - Get OHLC aggregate bars
- `get_previous_close/3` - Get previous day data
- `get_snapshot/2` - Get contract snapshot
- `get_last_trade/2` - Get last trade

### Indices
- `get_ticker/3` - Get index ticker details
- `list_indices/2` - List all indices
- `get_aggregates/7` - Get OHLC aggregate bars
- `get_previous_close/3` - Get previous day data
- `get_snapshot/2` - Get index snapshot

### Economy
- `get_treasury_yields/2` - Treasury yield data
- `get_inflation_data/3` - CPI/PCE inflation data
- `get_inflation_expectations/2` - Inflation expectations

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
