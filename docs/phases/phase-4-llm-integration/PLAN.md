---
date: 2026-02-15T14:10:00-05:00
phase: phase-4-llm-integration
status: ready
---

# Implementation Plan: Phase 4 — LLM Integration

## Overview
Add LLM provider behaviour, Anthropic implementation, chat completions public API, and REST endpoints (sync + streaming SSE).

## Implementation Approach
Five vertical slices, each testable independently:
1. Add `req` dependency + provider behaviour
2. Anthropic provider implementation with HTTP client abstraction
3. ChatCompletions public API facade
4. REST endpoint for sync chat completions
5. SSE streaming endpoint

## What We're NOT Doing
- Other providers (OpenAI, etc.)
- Agent-LLM binding
- Conversation persistence
- Token tracking / rate limiting

---

## Task 1: Foundation — Dependency + Provider Behaviour

### Changes
- Add `{:req, "~> 0.5"}` to `mix.exs` deps
- Create `lib/beamclaw2/llm/provider.ex` — behaviour with `chat/2` and `stream/2` callbacks
- Create `lib/beamclaw2/llm/http_client.ex` — behaviour for HTTP abstraction
- Create `lib/beamclaw2/llm/http_client/req_client.ex` — default Req implementation
- Add config in `config/config.exs` and `config/runtime.exs`

### Verification
- `mix deps.get && mix compile --warnings-as-errors`

---

## Task 2: Anthropic Provider

### Changes
- Create `lib/beamclaw2/llm/providers/anthropic.ex`
  - Implements `Provider` behaviour
  - `chat/2`: builds request, calls HTTP client, parses response
  - `stream/2`: builds request with `stream: true`, returns enumerable of chunks
- Create `test/beamclaw2/llm/providers/anthropic_test.exs`
  - Mock HTTP client returns canned Anthropic responses
  - Test success, API error, network error cases

### Verification
- `mix test test/beamclaw2/llm/providers/anthropic_test.exs`

---

## Task 3: ChatCompletions Facade

### Changes
- Create `lib/beamclaw2/llm/chat_completions.ex`
  - `complete/2` — sync chat completion
  - `stream/2` — streaming chat completion
  - Reads provider from config, delegates
- Create `test/beamclaw2/llm/chat_completions_test.exs`

### Verification
- `mix test test/beamclaw2/llm/chat_completions_test.exs`

---

## Task 4: Sync REST Endpoint

### Changes
- Create `lib/beamclaw2_web/controllers/chat_controller.ex`
- Create `lib/beamclaw2_web/controllers/chat_json.ex`
- Add route: `POST /api/chat/completions`
- Update FallbackController if needed for new error types
- Create `test/beamclaw2_web/controllers/chat_controller_test.exs`

### Verification
- `mix test test/beamclaw2_web/controllers/chat_controller_test.exs`

---

## Task 5: SSE Streaming Endpoint

### Changes
- Add `POST /api/chat/completions/stream` route
- Add `stream` action to ChatController using `Plug.Conn.chunk/2`
- Test with ConnCase (verify chunked response)

### Verification
- `mix test` (all tests pass)
- `mix compile --warnings-as-errors`
- `mix format --check-formatted`

---

## Testing Strategy

### Unit Tests
- Anthropic provider: mock HTTP client, test request building + response parsing
- ChatCompletions: mock provider, test delegation
- Edge cases: missing API key, malformed responses, network errors

### Integration Tests
- Controller tests via ConnCase with mocked provider
- Streaming tests verify chunked transfer encoding and SSE format
