defmodule Beamclaw2Web.ChatController do
  use Beamclaw2Web, :controller

  alias Beamclaw2.LLM.ChatCompletions

  action_fallback Beamclaw2Web.FallbackController

  @doc "POST /api/chat/completions"
  def create(conn, params) do
    with {:ok, messages} <- validate_messages(params),
         opts <- extract_opts(params),
         {:ok, completion} <- ChatCompletions.complete(messages, opts) do
      conn
      |> put_status(:ok)
      |> json(Beamclaw2Web.ChatJSON.completion(completion))
    end
  end

  @doc "POST /api/chat/completions/stream"
  def stream(conn, params) do
    with {:ok, messages} <- validate_messages(params),
         opts <- extract_opts(params),
         {:ok, chunks} <- ChatCompletions.stream(messages, opts) do
      conn =
        conn
        |> put_resp_content_type("text/event-stream")
        |> put_resp_header("cache-control", "no-cache")
        |> put_resp_header("connection", "keep-alive")
        |> send_chunked(200)

      Enum.reduce_while(chunks, conn, fn chunk, conn ->
        sse_data = Jason.encode!(Beamclaw2Web.ChatJSON.chunk(chunk))
        event = "event: #{chunk.type}\ndata: #{sse_data}\n\n"

        case Plug.Conn.chunk(conn, event) do
          {:ok, conn} -> {:cont, conn}
          {:error, :closed} -> {:halt, conn}
        end
      end)
    end
  end

  defp validate_messages(%{"messages" => messages}) when is_list(messages) and messages != [] do
    validated =
      Enum.map(messages, fn
        %{"role" => role, "content" => content}
        when role in ["user", "assistant", "system"] and is_binary(content) ->
          %{role: role, content: content}

        _ ->
          :invalid
      end)

    if Enum.any?(validated, &(&1 == :invalid)) do
      {:error, :invalid_messages}
    else
      {:ok, validated}
    end
  end

  defp validate_messages(_), do: {:error, :invalid_messages}

  defp extract_opts(params) do
    %{}
    |> maybe_put(:model, params["model"])
    |> maybe_put(:max_tokens, params["max_tokens"])
    |> maybe_put(:temperature, params["temperature"])
    |> maybe_put(:system, params["system"])
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
