defmodule Beamclaw2Web.ChatControllerTest do
  use Beamclaw2Web.ConnCase

  alias Beamclaw2.LLM.MockHttpClient

  setup do
    Application.put_env(:beamclaw2, :llm_http_client, MockHttpClient)
    Application.put_env(:beamclaw2, :anthropic_api_key, "test-key")

    on_exit(fn ->
      Application.delete_env(:beamclaw2, :llm_http_client)
    end)

    :ok
  end

  describe "POST /api/chat/completions" do
    test "returns completion on valid request", %{conn: conn} do
      MockHttpClient.set_response(
        {:ok,
         %{
           status: 200,
           body: %{
             "id" => "msg_ctrl",
             "model" => "claude-sonnet-4-20250514",
             "content" => [%{"type" => "text", "text" => "Hello from Claude"}],
             "stop_reason" => "end_turn",
             "usage" => %{"input_tokens" => 10, "output_tokens" => 5}
           },
           headers: []
         }}
      )

      conn =
        post(conn, "/api/chat/completions", %{
          "messages" => [%{"role" => "user", "content" => "Hi"}]
        })

      assert %{
               "id" => "msg_ctrl",
               "content" => "Hello from Claude",
               "model" => "claude-sonnet-4-20250514",
               "stop_reason" => "end_turn",
               "usage" => %{"input_tokens" => 10, "output_tokens" => 5}
             } = json_response(conn, 200)
    end

    test "returns 422 for missing messages", %{conn: conn} do
      conn = post(conn, "/api/chat/completions", %{})
      assert %{"error" => %{"message" => _}} = json_response(conn, 422)
    end

    test "returns 422 for empty messages array", %{conn: conn} do
      conn = post(conn, "/api/chat/completions", %{"messages" => []})
      assert %{"error" => %{"message" => _}} = json_response(conn, 422)
    end

    test "returns 422 for invalid message format", %{conn: conn} do
      conn =
        post(conn, "/api/chat/completions", %{
          "messages" => [%{"bad" => "format"}]
        })

      assert %{"error" => %{"message" => _}} = json_response(conn, 422)
    end

    test "returns 422 for invalid role", %{conn: conn} do
      conn =
        post(conn, "/api/chat/completions", %{
          "messages" => [%{"role" => "admin", "content" => "hack"}]
        })

      assert %{"error" => %{"message" => _}} = json_response(conn, 422)
    end

    test "returns 503 when API key is missing", %{conn: conn} do
      Application.delete_env(:beamclaw2, :anthropic_api_key)

      conn =
        post(conn, "/api/chat/completions", %{
          "messages" => [%{"role" => "user", "content" => "Hi"}]
        })

      assert %{"error" => %{"message" => "LLM provider not configured"}} =
               json_response(conn, 503)
    end

    test "returns 502 on API error", %{conn: conn} do
      MockHttpClient.set_response(
        {:ok,
         %{
           status: 500,
           body: %{"error" => %{"message" => "Internal server error"}},
           headers: []
         }}
      )

      conn =
        post(conn, "/api/chat/completions", %{
          "messages" => [%{"role" => "user", "content" => "Hi"}]
        })

      assert %{"error" => %{"message" => "LLM provider error"}} = json_response(conn, 502)
    end

    test "accepts optional model and system params", %{conn: conn} do
      MockHttpClient.set_response(
        {:ok,
         %{
           status: 200,
           body: %{
             "id" => "msg_opt",
             "model" => "claude-opus-4-20250514",
             "content" => [%{"type" => "text", "text" => "Deep"}],
             "stop_reason" => "end_turn",
             "usage" => %{"input_tokens" => 15, "output_tokens" => 1}
           },
           headers: []
         }}
      )

      conn =
        post(conn, "/api/chat/completions", %{
          "messages" => [%{"role" => "user", "content" => "Think"}],
          "model" => "claude-opus-4-20250514",
          "system" => "You are wise",
          "max_tokens" => 2048
        })

      assert %{"model" => "claude-opus-4-20250514"} = json_response(conn, 200)
    end
  end

  describe "POST /api/chat/completions/stream" do
    test "returns SSE stream on valid request", %{conn: conn} do
      sse_data = """
      event: content_block_delta\ndata: {"type":"content_block_delta","delta":{"type":"text_delta","text":"Hi"}}\n
      event: message_stop\ndata: {"type":"message_stop"}\n
      """

      MockHttpClient.set_stream_response({:ok, [sse_data]})

      conn =
        post(conn, "/api/chat/completions/stream", %{
          "messages" => [%{"role" => "user", "content" => "Hello"}]
        })

      assert conn.status == 200
      assert {"content-type", "text/event-stream; charset=utf-8"} in conn.resp_headers
      assert conn.resp_body =~ "content_delta"
    end

    test "returns 422 for invalid messages on stream", %{conn: conn} do
      conn = post(conn, "/api/chat/completions/stream", %{})
      assert %{"error" => %{"message" => _}} = json_response(conn, 422)
    end
  end
end
