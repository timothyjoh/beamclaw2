---
date: 2026-02-15T14:05:00-05:00
phase: phase-4-llm-integration
status: complete
---

# Research: Phase 4 — LLM Integration

## Phase Context
Build the LLM provider abstraction layer and Anthropic integration so BeamClaw2 agents can perform chat completions.

## Previous Phase Learnings
- Facade pattern (AgentManager) works well — replicate for LLM module
- FallbackController keeps controllers clean
- Validate at controller boundary, not in business logic
- View modules (AgentJSON) give explicit serialization control

## Current Codebase State

### Relevant Components
- `Beamclaw2.AgentManager` — facade pattern to follow (`lib/beamclaw2/agent_manager.ex`)
- `Beamclaw2Web.AgentController` — controller pattern (`lib/beamclaw2_web/controllers/agent_controller.ex`)
- `Beamclaw2Web.FallbackController` — error handling (`lib/beamclaw2_web/controllers/fallback_controller.ex`)
- `Beamclaw2Web.Router` — route definitions (`lib/beamclaw2_web/router.ex`)

### Existing Patterns
- **Facade**: Public API module wraps internal implementation
- **FallbackController**: Controllers return `{:ok, data}` or `{:error, reason}` tuples
- **View modules**: JSON serialization in dedicated `*JSON` modules
- **Config**: `config/` directory with per-env files, `runtime.exs` for runtime config

### Dependencies
- `jason` for JSON encoding/decoding
- `bandit` for HTTP server
- No HTTP client library yet — need to add `req`

### Test Infrastructure
- ExUnit with `async: true` where possible
- `Beamclaw2Web.ConnCase` for controller tests
- Tests at `test/beamclaw2/` (unit) and `test/beamclaw2_web/` (integration)
- 54 tests currently passing

## Anthropic Messages API Reference
- Endpoint: `POST https://api.anthropic.com/v1/messages`
- Headers: `x-api-key`, `anthropic-version: 2023-06-01`, `content-type: application/json`
- Request body: `{model, messages: [{role, content}], max_tokens, stream?}`
- Response: `{id, type, role, content: [{type: "text", text}], model, stop_reason, usage}`
- Streaming: SSE with `event: content_block_delta`, `data: {type: "content_block_delta", delta: {type: "text_delta", text}}`
- Stream events: `message_start`, `content_block_start`, `content_block_delta`, `content_block_stop`, `message_delta`, `message_stop`

## Architecture Decision: HTTP Client Abstraction
Use a configurable HTTP client module for testability:
- `Beamclaw2.LLM.HttpClient` behaviour with `post/3`
- Default implementation uses `Req`
- Test implementation returns canned responses
- Configured via application env: `config :beamclaw2, :llm_http_client`
