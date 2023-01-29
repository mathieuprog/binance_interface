defmodule BinanceInterface.Request do
  @enforce_keys [:base_url, :endpoint_path]
  defstruct [
    :base_url,
    :endpoint_path,
    headers: [],
    body_data: [],
    query_params: [],
    signed?: false
  ]

  def new_request(base_url, endpoint_path, api_key \\ nil) do
    %__MODULE__{
      base_url: base_url,
      endpoint_path: endpoint_path
    }
    |> maybe_add_header("X-MBX-APIKEY", api_key)
  end

  def url(%{base_url: base_url, endpoint_path: endpoint_path} = request) do
    Path.join(base_url, endpoint_path) <> query_string(request, prepend_?: true)
  end

  def query_string(%{query_params: query_params}, prepend_?: prepend_?) do
    if(prepend_?, do: "?", else: "") <> URI.encode_query(query_params)
  end

  def headers(%{headers: headers}) do
    headers
  end

  def body(%{body_data: body_data}) do
    URI.encode_query(body_data)
  end

  def add_header(_request, key, _value) when not is_binary(key) do
    raise "key must be a string"
  end

  def add_header(%{headers: headers} = request, key, value) do
    %{request | headers: headers ++ [{key, value}]}
  end

  def maybe_add_header(request, key, value) do
    if value, do: add_header(request, key, value), else: request
  end

  def add_body_data(_request, key, _value) when not is_binary(key) do
    raise "key must be a string"
  end

  def add_body_data(%{signed?: true}, _key, _value) do
    raise "request data already signed"
  end

  def add_body_data(%{body_data: body_data} = request, key, value) do
    %{request | body_data: body_data ++ [{key, value}]}
  end

  def maybe_add_body_data(request, key, value) do
    if value, do: add_body_data(request, key, value), else: request
  end

  def add_query_param(_request, key, _value) when not is_binary(key) do
    raise "key must be a string"
  end

  def add_query_param(%{signed?: true}, key, _value) when key != "signature" do
    raise "request data already signed"
  end

  def add_query_param(%{query_params: query_params} = request, key, value) do
    %{request | query_params: query_params ++ [{key, value}]}
  end

  def maybe_add_query_param(request, key, value) do
    if value, do: add_query_param(request, key, value), else: request
  end

  def add_signature(request, secret_key, opts \\ []) do
    request =
      request
      |> add_query_param("timestamp", System.os_time(:millisecond))
      |> add_query_param("recvWindow", Keyword.get(opts, :expires_after_ms, 5000))

    payload = URI.encode_query(request.query_params) <> URI.encode_query(request.body_data)

    signature =
      :crypto.mac(:hmac, :sha256, secret_key, payload)
      |> Base.encode16()

    request
    |> add_query_param("signature", signature)
    |> Map.put(:signed?, true)
  end
end
