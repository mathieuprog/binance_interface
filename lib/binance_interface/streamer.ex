defmodule BinanceInterface.Streamer do
  # Also see https://github.com/phoenixframework/phoenix/blob/4da71906da970a162c88e165cdd2fdfaf9083ac3/test/support/websocket_client.exs
  use GenServer

  require Logger
  require Mint.HTTP

  defstruct [
    :conn,
    :request_ref,
    :websocket,
    :caller,
    :status,
    :resp_headers
  ]

  def connect(url) do
    with {:ok, socket} <- GenServer.start_link(__MODULE__, []),
         {:ok, :connected} <- GenServer.call(socket, {:connect, url}) do
      {:ok, socket}
    end
  end

  @impl GenServer
  def init([]) do
    {:ok, %__MODULE__{}}
  end

  @impl GenServer
  def handle_call({:connect, url}, from, state) do
    uri = URI.parse(url)

    http_scheme =
      case uri.scheme do
        "ws" -> :http
        "wss" -> :https
      end

    ws_scheme =
      case uri.scheme do
        "ws" -> :ws
        "wss" -> :wss
      end

    path =
      case uri.query do
        nil -> uri.path
        query -> uri.path <> "?" <> query
      end

    with {:ok, conn} <- Mint.HTTP.connect(http_scheme, uri.host, uri.port, protocols: [:http1]),
         {:ok, conn, ref} <- Mint.WebSocket.upgrade(ws_scheme, conn, path, []) do
      state = %{state | conn: conn, request_ref: ref, caller: from}
      {:noreply, state}
    else
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      {:error, conn, reason} ->
        {:reply, {:error, reason}, put_in(state.conn, conn)}
    end
  end

  @impl GenServer
  def handle_info(message, state) do
    case Mint.WebSocket.stream(state.conn, message) do
      {:ok, conn, responses} ->
        state = put_in(state.conn, conn) |> handle_responses(responses)
        {:noreply, state}

      {:error, conn, reason, _responses} ->
        state = put_in(state.conn, conn) |> reply({:error, reason})
        {:noreply, state}

      :unknown ->
        {:noreply, state}
    end
  end

  defp handle_responses(state, responses)

  defp handle_responses(%{request_ref: ref} = state, [{:status, ref, status} | rest]) do
    put_in(state.status, status)
    |> handle_responses(rest)
  end

  defp handle_responses(%{request_ref: ref} = state, [{:headers, ref, resp_headers} | rest]) do
    put_in(state.resp_headers, resp_headers)
    |> handle_responses(rest)
  end

  defp handle_responses(%{request_ref: ref} = state, [{:done, ref} | rest]) do
    case Mint.WebSocket.new(state.conn, ref, state.status, state.resp_headers) do
      {:ok, conn, websocket} ->
        %{state | conn: conn, websocket: websocket, status: nil, resp_headers: nil}
        |> reply({:ok, :connected})
        |> handle_responses(rest)

      {:error, conn, reason} ->
        put_in(state.conn, conn)
        |> reply({:error, reason})
    end
  end

  defp handle_responses(%{request_ref: ref, websocket: websocket} = state, [
         {:data, ref, data} | rest
       ])
       when websocket != nil do
    case Mint.WebSocket.decode(websocket, data) do
      {:ok, websocket, frames} ->
        put_in(state.websocket, websocket)
        |> handle_frames(frames)
        |> handle_responses(rest)

      {:error, websocket, reason} ->
        put_in(state.websocket, websocket)
        |> reply({:error, reason})
    end
  end

  defp handle_responses(state, [_response | rest]) do
    handle_responses(state, rest)
  end

  defp handle_responses(state, []), do: state

  defp handle_frames(state, frames) do
    Enum.reduce(frames, state, fn
      # reply to ping with pong
      {:ping, data}, state ->
        {:ok, state} = stream_frame(state, {:pong, data})
        state

      {:text, text}, state ->
        case Jason.decode(text) do
          {:ok, event} ->
            Logger.debug("Received Json decoded: #{inspect(event)}")
            process_event(event)
          {:error, _} -> Logger.error("Unable to parse msg: #{inspect(text)}")
        end
        state

      frame, state ->
        Logger.debug("Unexpected frame received: #{inspect(frame)}")
        state
    end)
  end

  defp stream_frame(state, frame) do
    with {:ok, websocket, data} <- Mint.WebSocket.encode(state.websocket, frame),
         state = put_in(state.websocket, websocket),
         {:ok, conn} <- Mint.WebSocket.stream_request_body(state.conn, state.request_ref, data) do
      {:ok, put_in(state.conn, conn)}
    else
      {:error, %Mint.WebSocket{} = websocket, reason} ->
        {:error, put_in(state.websocket, websocket), reason}

      {:error, conn, reason} ->
        {:error, put_in(state.conn, conn), reason}
    end
  end

  defp reply(state, response) do
    if state.caller, do: GenServer.reply(state.caller, response)
    put_in(state.caller, nil)
  end

  defp process_event(%{"e" => "trade"} = event) do
    trade_event = %Streamer.Binance.TradeEvent{
      event_type: event["e"],
      event_time: event["E"],
      symbol: event["s"],
      trade_id: event["t"],
      price: event["p"],
      quantity: event["q"],
      buyer_order_id: event["b"],
      seller_order_id: event["a"],
      trade_time: event["T"],
      buyer_market_maker: event["m"]
    }

    Logger.debug(
      "Trade event received " <>
        "#{trade_event.symbol}@#{trade_event.price}"
    )

    Phoenix.PubSub.broadcast(
      Streamer.PubSub,
      "TRADE_EVENTS:#{trade_event.symbol}",
      trade_event
    )
  end
end
