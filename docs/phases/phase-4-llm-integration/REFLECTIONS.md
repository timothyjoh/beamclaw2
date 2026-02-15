# Phase 4: LLM Integration — Reflections

## What Went Well

### Behaviour-Based Provider Abstraction
The `Provider` behaviour with `chat/2` and `stream/2` callbacks provides a clean contract. Adding new providers (OpenAI, Ollama) is just implementing two functions. The HTTP client abstraction makes testing trivial — swap `ReqClient` for `MockHttpClient` in tests.

### Facade Pattern Consistency
`ChatCompletions` follows the same pattern as `AgentManager` — clean public API that hides provider selection and delegation. The web layer only knows about `ChatCompletions`, never about `Anthropic` directly.

### Mock via Process Dictionary
Using `Process.put/2` for per-test mock responses works perfectly with `async: true` tests. No global state, no Mox dependency, no complexity. Each test sets its own expected HTTP response.

### FallbackController Extension
Adding new error clauses (`:invalid_messages`, `:missing_api_key`, `:api_error`) was seamless. The pattern of controllers returning error tuples and the fallback handling HTTP responses continues to scale well.

## What Didn't Go Well
Nothing significant. The SSE streaming test is slightly simplified — it tests that chunked encoding works and the right content type is set, but doesn't fully simulate a real SSE client. Adequate for unit testing.

## Architectural Decisions

1. **Configurable HTTP client via app env**: `Application.get_env(:beamclaw2, :llm_http_client)` — simple, testable, no DI framework needed.
2. **SSE over WebSocket for streaming**: SSE is simpler, HTTP-native, and sufficient for server→client streaming. WebSocket adds complexity for no benefit here.
3. **Process dictionary mocks over Mox**: Lighter weight, no extra dependency, works with async tests. Trade-off: less strict expectation checking.
4. **Provider module in opts**: `ChatCompletions.complete(msgs, %{provider: MyProvider})` allows per-call provider override while defaulting from config.

## Metrics
- **Tests**: 74 total (20 new), 0 failures
- **Warnings**: 0
- **New modules**: 7 (Provider, HttpClient, ReqClient, Anthropic, ChatCompletions, ChatController, ChatJSON)
- **New test files**: 3 + 1 support module (MockHttpClient)

## Carry-Forward for Phase 5
- Agent-LLM binding: agents can execute chat completions as tasks
- Conversation history/memory per agent
- OpenAI provider implementation
- Token usage tracking and budgets
- Real streaming (currently collects chunks then sends — true streaming would pipe SSE events as they arrive from Anthropic)
- Rate limiting per provider
- Integration test with real Anthropic API (tagged, skipped in CI)
