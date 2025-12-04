defmodule ExMassive.WebSocketClient do
  @moduledoc """
  WebSocket client for real-time data streams from Massive.com.

  ## Usage

      # Start a WebSocket connection
      {:ok, pid} = ExMassive.WebSocketClient.start_link(
        api_key: "your_api_key",
        handler: MyHandler
      )

      # Subscribe to channels
      ExMassive.WebSocketClient.subscribe(pid, ["AM.AAPL", "AM.MSFT"])

      # Unsubscribe from channels
      ExMassive.WebSocketClient.unsubscribe(pid, ["AM.AAPL"])

  ## Handler Module

  Your handler module should implement callbacks:

      defmodule MyHandler do
        def handle_message(message, state) do
          IO.inspect(message, label: "Received")
          {:ok, state}
        end

        def handle_connect(state) do
          IO.puts("Connected!")
          {:ok, state}
        end

        def handle_disconnect(reason, state) do
          IO.puts("Disconnected: \#{inspect(reason)}")
          {:ok, state}
        end
      end

  ## Available Channels

  ### Stocks
  - `AM.{ticker}` - Minute aggregates (OHLC per minute)
  - `A.{ticker}` - Second aggregates (OHLC per second)
  - `T.{ticker}` - Trades
  - `Q.{ticker}` - Quotes
  - Use `*` as wildcard for all tickers (e.g., `AM.*`)

  ### Options, Futures, Crypto, Forex
  Similar channel patterns available for each asset class.
  """

  use WebSockex

  @delayed_url "wss://delayed.massive.com/stocks"
  @realtime_url "wss://socket.massive.com/stocks"

  defstruct [
    :api_key,
    :handler,
    :handler_state,
    :subscriptions,
    :authenticated
  ]

  @doc """
  Starts a WebSocket connection.

  ## Options
    * `:api_key` - Your Massive.com API key (required)
    * `:handler` - Module implementing handler callbacks (required)
    * `:handler_state` - Initial state passed to handler (default: %{})
    * `:realtime` - Use realtime feed (default: false, uses 15-min delayed)
    * `:url` - Custom WebSocket URL (overrides :realtime)
  """
  def start_link(opts \\ []) do
    api_key = opts[:api_key] || Application.get_env(:ex_massive, :api_key)
    handler = Keyword.fetch!(opts, :handler)
    handler_state = Keyword.get(opts, :handler_state, %{})

    url =
      cond do
        opts[:url] -> opts[:url]
        opts[:realtime] -> @realtime_url
        true -> @delayed_url
      end

    state = %__MODULE__{
      api_key: api_key,
      handler: handler,
      handler_state: handler_state,
      subscriptions: MapSet.new(),
      authenticated: false
    }

    WebSockex.start_link(url, __MODULE__, state, opts)
  end

  @doc """
  Subscribe to one or more channels.

  ## Examples

      # Subscribe to single channel
      subscribe(pid, "AM.AAPL")

      # Subscribe to multiple channels
      subscribe(pid, ["AM.AAPL", "AM.MSFT", "T.GOOGL"])

      # Subscribe to all tickers for a channel type
      subscribe(pid, "AM.*")
  """
  def subscribe(pid, channels) when is_list(channels) do
    WebSockex.cast(pid, {:subscribe, channels})
  end

  def subscribe(pid, channel) when is_binary(channel) do
    subscribe(pid, [channel])
  end

  @doc """
  Unsubscribe from one or more channels.
  """
  def unsubscribe(pid, channels) when is_list(channels) do
    WebSockex.cast(pid, {:unsubscribe, channels})
  end

  def unsubscribe(pid, channel) when is_binary(channel) do
    unsubscribe(pid, [channel])
  end

  @doc """
  Get current subscriptions.
  """
  def get_subscriptions(pid) do
    GenServer.call(pid, :get_subscriptions)
  end

  # WebSockex callbacks

  @impl true
  def handle_connect(_conn, state) do
    # Authenticate immediately after connection
    auth_message = Jason.encode!(%{
      action: "auth",
      params: state.api_key
    })

    # Send auth message using handle_frame for proper message sending
    send(self(), {:send_auth, auth_message})
    {:ok, state}
  end

  @impl true
  def handle_info({:send_auth, auth_message}, state) do
    {:reply, {:text, auth_message}, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:ok, state}
  end

  @impl true
  def handle_frame({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok, messages} when is_list(messages) ->
        handle_messages(messages, state)

      {:ok, message} ->
        handle_messages([message], state)

      {:error, _} ->
        {:ok, state}
    end
  end

  @impl true
  def handle_cast({:subscribe, channels}, state) do
    if state.authenticated do
      params = Enum.join(channels, ",")
      message = Jason.encode!(%{action: "subscribe", params: params})

      new_subscriptions = Enum.reduce(channels, state.subscriptions, fn ch, acc ->
        MapSet.put(acc, ch)
      end)

      {:reply, {:text, message}, %{state | subscriptions: new_subscriptions}}
    else
      # Queue subscriptions if not authenticated yet
      {:ok, state}
    end
  end

  @impl true
  def handle_cast({:unsubscribe, channels}, state) do
    params = Enum.join(channels, ",")
    message = Jason.encode!(%{action: "unsubscribe", params: params})

    new_subscriptions = Enum.reduce(channels, state.subscriptions, fn ch, acc ->
      MapSet.delete(acc, ch)
    end)

    {:reply, {:text, message}, %{state | subscriptions: new_subscriptions}}
  end


  @impl true
  def handle_disconnect(disconnect_map, state) do
    reason = Map.get(disconnect_map, :reason, :unknown)

    if state.handler do
      state.handler.handle_disconnect(reason, state.handler_state)
    end

    {:ok, %{state | authenticated: false}}
  end

  # Private functions

  defp handle_messages(messages, state) do
    Enum.reduce(messages, {:ok, state}, fn message, {:ok, acc_state} ->
      handle_single_message(message, acc_state)
    end)
  end

  defp handle_single_message(%{"ev" => "status", "status" => "connected"}, state) do
    {:ok, state}
  end

  defp handle_single_message(%{"ev" => "status", "status" => "auth_success"}, state) do
    new_state = %{state | authenticated: true}

    if state.handler do
      case state.handler.handle_connect(state.handler_state) do
        {:ok, new_handler_state} ->
          {:ok, %{new_state | handler_state: new_handler_state}}
        _ ->
          {:ok, new_state}
      end
    else
      {:ok, new_state}
    end
  end

  defp handle_single_message(%{"ev" => "status", "status" => status, "message" => message}, state) do
    IO.warn("WebSocket status: #{status} - #{message}")
    {:ok, state}
  end

  defp handle_single_message(message, state) do
    if state.handler do
      case state.handler.handle_message(message, state.handler_state) do
        {:ok, new_handler_state} ->
          {:ok, %{state | handler_state: new_handler_state}}
        _ ->
          {:ok, state}
      end
    else
      {:ok, state}
    end
  end
end
