defmodule Beamclaw2.LLM.Providers.AnthropicTest do
  use ExUnit.Case, async: true

  alias Beamclaw2.LLM.Providers.Anthropic
  alias Beamclaw2.LLM.MockHttpClient

  setup do
    Application.put_env(:beamclaw2, :llm_http_client, MockHttpClient)
    Application.put_env(:beamclaw2, :anthropic_api_key, "test-key")

    on_exit(fn ->
      Application.delete_env(:beamclaw2, :llm_http_client)
    end)

    :ok
  end

  describe "chat/2" do
    test "returns completion on success" do
      MockHttpClient.set_response(
        {:ok,
         %{
           status: 200,
           body: %{
             "id" => "msg_123",
             "model" => "claude-sonnet-4-20250514",
             "content" => [%{"type" => "text", "text" => "Hello!"}],
             "stop_reason" => "end_turn",
             "usage" => %{"input_tokens" => 10, "output_tokens" => 5}
           },
           headers: []
         }}
      )

      messages = [%{role: "user", content: "Hi"}]
      assert {:ok, completion} = Anthropic.chat(messages)
      assert completion.id == "msg_123"
      assert completion.content == "Hello!"
      assert completion.stop_reason == "end_turn"
      assert completion.usage.input_tokens == 10
      assert completion.usage.output_tokens == 5
    end

    test "returns error on API error" do
      MockHttpClient.set_response(
        {:ok,
         %{
           status: 401,
           body: %{"error" => %{"message" => "Invalid API key"}},
           headers: []
         }}
      )

      messages = [%{role: "user", content: "Hi"}]
      assert {:error, :api_error, %{status: 401}} = Anthropic.chat(messages)
    end

    test "returns error on network failure" do
      MockHttpClient.set_response({:error, :timeout})

      messages = [%{role: "user", content: "Hi"}]
      assert {:error, :timeout} = Anthropic.chat(messages)
    end

    test "returns error when API key is missing" do
      Application.delete_env(:beamclaw2, :anthropic_api_key)

      messages = [%{role: "user", content: "Hi"}]
      assert {:error, :missing_api_key} = Anthropic.chat(messages)
    end

    test "passes custom options" do
      MockHttpClient.set_response(
        {:ok,
         %{
           status: 200,
           body: %{
             "id" => "msg_456",
             "model" => "claude-opus-4-20250514",
             "content" => [%{"type" => "text", "text" => "Deep thought"}],
             "stop_reason" => "end_turn",
             "usage" => %{"input_tokens" => 20, "output_tokens" => 100}
           },
           headers: []
         }}
      )

      messages = [%{role: "user", content: "Think deeply"}]

      assert {:ok, completion} =
               Anthropic.chat(messages, %{
                 model: "claude-opus-4-20250514",
                 max_tokens: 4096,
                 temperature: 0.7,
                 system: "You are a philosopher"
               })

      assert completion.model == "claude-opus-4-20250514"
    end
  end

  describe "stream/2" do
    test "parses SSE chunks" do
      sse_data = """
      event: message_start\ndata: {"type":"message_start","message":{"id":"msg_1"}}\n
      event: content_block_delta\ndata: {"type":"content_block_delta","delta":{"type":"text_delta","text":"Hello"}}\n
      event: content_block_delta\ndata: {"type":"content_block_delta","delta":{"type":"text_delta","text":" world"}}\n
      event: message_stop\ndata: {"type":"message_stop"}\n
      """

      MockHttpClient.set_stream_response({:ok, [sse_data]})

      messages = [%{role: "user", content: "Hi"}]
      assert {:ok, chunks} = Anthropic.stream(messages)
      assert length(chunks) == 4

      types = Enum.map(chunks, & &1.type)
      assert :message_start in types
      assert :content_delta in types
      assert :message_stop in types

      text_chunks = Enum.filter(chunks, &(&1.type == :content_delta))
      full_text = Enum.map_join(text_chunks, "", & &1.content)
      assert full_text == "Hello world"
    end

    test "returns error on API error during stream" do
      MockHttpClient.set_stream_response(
        {:ok, %{status: 429, body: %{"error" => "rate_limited"}, headers: []}}
      )

      messages = [%{role: "user", content: "Hi"}]
      assert {:error, :api_error, %{status: 429}} = Anthropic.stream(messages)
    end
  end
end
