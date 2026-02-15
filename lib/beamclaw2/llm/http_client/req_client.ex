defmodule Beamclaw2.LLM.HttpClient.ReqClient do
  @moduledoc """
  Default HTTP client implementation using Req.
  """

  @behaviour Beamclaw2.LLM.HttpClient

  @impl true
  def post(url, headers, body) do
    case Req.post(url, json: body, headers: Map.new(headers), receive_timeout: 60_000) do
      {:ok, %Req.Response{status: status, body: resp_body, headers: resp_headers}} ->
        flat_headers =
          Enum.flat_map(resp_headers, fn {k, v} ->
            if is_list(v), do: Enum.map(v, &{k, &1}), else: [{k, v}]
          end)

        {:ok, %{status: status, body: resp_body, headers: flat_headers}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def post_stream(url, headers, body) do
    stream_body = Map.put(body, "stream", true)

    case Req.post(url,
           json: stream_body,
           headers: Map.new(headers),
           receive_timeout: 120_000,
           into: :self
         ) do
      {:ok, %Req.Response{status: 200} = resp} ->
        chunks = collect_stream_chunks(resp)
        {:ok, chunks}

      {:ok, %Req.Response{status: status, body: resp_body}} ->
        {:ok, %{status: status, body: resp_body, headers: []}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp collect_stream_chunks(resp) do
    collect_stream_chunks(resp, [])
  end

  defp collect_stream_chunks(_resp, acc) do
    receive do
      {_ref, {:data, data}} ->
        collect_stream_chunks(nil, [data | acc])

      {_ref, :done} ->
        Enum.reverse(acc)
    after
      30_000 ->
        Enum.reverse(acc)
    end
  end
end
