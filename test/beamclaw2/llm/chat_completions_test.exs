defmodule Beamclaw2.LLM.ChatCompletionsTest do
  use ExUnit.Case, async: true

  alias Beamclaw2.LLM.ChatCompletions
  alias Beamclaw2.LLM.MockHttpClient

  setup do
    Application.put_env(:beamclaw2, :llm_http_client, MockHttpClient)
    Application.put_env(:beamclaw2, :anthropic_api_key, "test-key")

    on_exit(fn ->
      Application.delete_env(:beamclaw2, :llm_http_client)
    end)

    :ok
  end

  describe "complete/2" do
    test "delegates to provider and returns completion" do
      MockHttpClient.set_response(
        {:ok,
         %{
           status: 200,
           body: %{
             "id" => "msg_cc",
             "model" => "claude-sonnet-4-20250514",
             "content" => [%{"type" => "text", "text" => "Response"}],
             "stop_reason" => "end_turn",
             "usage" => %{"input_tokens" => 5, "output_tokens" => 3}
           },
           headers: []
         }}
      )

      assert {:ok, result} = ChatCompletions.complete([%{role: "user", content: "Test"}])
      assert result.content == "Response"
    end

    test "passes options through" do
      MockHttpClient.set_response(
        {:ok,
         %{
           status: 200,
           body: %{
             "id" => "msg_opt",
             "model" => "claude-opus-4-20250514",
             "content" => [%{"type" => "text", "text" => "OK"}],
             "stop_reason" => "end_turn",
             "usage" => %{"input_tokens" => 1, "output_tokens" => 1}
           },
           headers: []
         }}
      )

      assert {:ok, _} =
               ChatCompletions.complete([%{role: "user", content: "Test"}], %{
                 model: "claude-opus-4-20250514"
               })
    end
  end

  describe "stream/2" do
    test "delegates to provider for streaming" do
      sse =
        "event: content_block_delta\ndata: {\"type\":\"content_block_delta\",\"delta\":{\"type\":\"text_delta\",\"text\":\"Hi\"}}\n\n"

      MockHttpClient.set_stream_response({:ok, [sse]})

      assert {:ok, chunks} = ChatCompletions.stream([%{role: "user", content: "Test"}])
      assert [%{type: :content_delta, content: "Hi"}] = chunks
    end
  end
end
