defmodule Beamclaw2.LLM.Providers.Anthropic do
  @moduledoc """
  Anthropic Claude provider implementation.
  Uses the Messages API (https://api.anthropic.com/v1/messages).
  """

  @behaviour Beamclaw2.LLM.Provider

  @api_url "https://api.anthropic.com/v1/messages"
  @api_version "2023-06-01"
  @default_model "claude-sonnet-4-20250514"
  @default_max_tokens 1024

  @impl true
  def chat(messages, opts \\ %{}) do
    with {:ok, api_key} <- get_api_key(),
         body <- build_request_body(messages, opts),
         {:ok, response} <- http_client().post(@api_url, headers(api_key), body) do
      parse_response(response)
    end
  end

  @impl true
  def stream(messages, opts \\ %{}) do
    with {:ok, api_key} <- get_api_key(),
         body <- build_request_body(messages, opts),
         {:ok, data} <- http_client().post_stream(@api_url, headers(api_key), body) do
      case data do
        %{status: status, body: body} when status >= 400 ->
          {:error, :api_error, %{status: status, body: body}}

        chunks when is_list(chunks) ->
          parsed = Enum.flat_map(chunks, &parse_sse_events/1)
          {:ok, parsed}
      end
    end
  end

  defp headers(api_key) do
    [
      {"x-api-key", api_key},
      {"anthropic-version", @api_version},
      {"content-type", "application/json"}
    ]
  end

  defp build_request_body(messages, opts) do
    body = %{
      "model" => Map.get(opts, :model, @default_model),
      "max_tokens" => Map.get(opts, :max_tokens, @default_max_tokens),
      "messages" => Enum.map(messages, &normalize_message/1)
    }

    body =
      case Map.get(opts, :temperature) do
        nil -> body
        temp -> Map.put(body, "temperature", temp)
      end

    case Map.get(opts, :system) do
      nil -> body
      system -> Map.put(body, "system", system)
    end
  end

  defp normalize_message(%{role: role, content: content}) do
    %{"role" => to_string(role), "content" => to_string(content)}
  end

  defp normalize_message(%{"role" => _role, "content" => _content} = msg), do: msg

  defp parse_response(%{status: 200, body: body}) when is_map(body) do
    content =
      body
      |> Map.get("content", [])
      |> Enum.filter(&(&1["type"] == "text"))
      |> Enum.map_join("", & &1["text"])

    {:ok,
     %{
       id: body["id"],
       model: body["model"],
       content: content,
       stop_reason: body["stop_reason"],
       usage: %{
         input_tokens: get_in(body, ["usage", "input_tokens"]) || 0,
         output_tokens: get_in(body, ["usage", "output_tokens"]) || 0
       }
     }}
  end

  defp parse_response(%{status: status, body: body}) when status >= 400 do
    {:error, :api_error, %{status: status, body: body}}
  end

  defp parse_response(%{status: _status, body: body}) do
    {:error, :api_error, %{status: 500, body: body}}
  end

  defp parse_sse_events(data) when is_binary(data) do
    data
    |> String.split("\n\n", trim: true)
    |> Enum.flat_map(&parse_single_sse_event/1)
  end

  defp parse_single_sse_event(event_str) do
    lines = String.split(event_str, "\n", trim: true)

    event_type =
      Enum.find_value(lines, fn
        "event: " <> type -> String.trim(type)
        _ -> nil
      end)

    data_line =
      Enum.find_value(lines, fn
        "data: " <> json -> String.trim(json)
        _ -> nil
      end)

    case {event_type, data_line} do
      {nil, _} ->
        []

      {_, nil} ->
        []

      {"content_block_delta", json} ->
        case Jason.decode(json) do
          {:ok, %{"delta" => %{"text" => text}}} ->
            [%{type: :content_delta, content: text, metadata: %{}}]

          _ ->
            []
        end

      {"message_start", json} ->
        case Jason.decode(json) do
          {:ok, data} ->
            [%{type: :message_start, content: nil, metadata: data}]

          _ ->
            []
        end

      {"message_stop", _json} ->
        [%{type: :message_stop, content: nil, metadata: %{}}]

      {_other, _json} ->
        []
    end
  end

  defp get_api_key do
    case Application.get_env(:beamclaw2, :anthropic_api_key) do
      nil -> {:error, :missing_api_key}
      "" -> {:error, :missing_api_key}
      key -> {:ok, key}
    end
  end

  defp http_client do
    Application.get_env(:beamclaw2, :llm_http_client, Beamclaw2.LLM.HttpClient.ReqClient)
  end
end
