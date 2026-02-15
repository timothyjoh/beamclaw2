---
date: 2026-02-15T14:00:00-05:00
phase: phase-4-llm-integration
phase_number: 4
phase_name: "LLM Integration"
status: ready
---

# Phase 4: LLM Integration

## Objective
Add LLM provider abstraction and chat completion capability to BeamClaw2. This is the core intelligence layer — agents need to talk to LLMs. We build a behaviour-based provider system with an Anthropic implementation, chat completion API endpoint, and streaming support.

## Scope

### In Scope
- LLM provider behaviour (contract for any LLM backend)
- Anthropic Claude provider implementation (Messages API)
- Chat completions context module (public API)
- REST endpoint: `POST /api/chat/completions`
- Streaming support via SSE (Server-Sent Events)
- HTTP client integration (Req library)
- Configuration management for API keys
- Comprehensive tests with mocked HTTP responses

### Out of Scope
- OpenAI/other provider implementations (future phase)
- Agent-to-LLM binding (agents auto-chatting — future phase)
- Conversation history/persistence
- Token counting/usage tracking
- Rate limiting
- WebSocket transport (SSE is sufficient for now)

## Requirements
- Provider behaviour defines `chat/2` and `stream/2` callbacks
- Anthropic provider hits `https://api.anthropic.com/v1/messages`
- Chat completions module is the public API (like AgentManager pattern)
- REST endpoint accepts messages array, model, optional params
- Streaming endpoint returns SSE `text/event-stream` responses
- API key configured via application config (runtime.exs)
- All HTTP calls go through a configurable HTTP client (testable)

## Acceptance Criteria
- [ ] `Beamclaw2.LLM.Provider` behaviour exists with `chat/2` and `stream/2`
- [ ] `Beamclaw2.LLM.Providers.Anthropic` implements the behaviour
- [ ] `Beamclaw2.LLM.ChatCompletions` public API works
- [ ] `POST /api/chat/completions` returns LLM response
- [ ] Streaming endpoint returns SSE chunks
- [ ] Tests cover success, error, and streaming cases with mocked HTTP
- [ ] All 54+ existing tests still pass
- [ ] Code compiles without warnings
- [ ] `mix format --check-formatted` passes

## Dependencies
- Phases 1-3 complete (Phoenix app, agents, REST API)
- `req` hex package for HTTP client
- Anthropic API key for integration testing (mocked in unit tests)

## Adjustments from Previous Phase
- Follow the facade pattern (AgentManager style) for ChatCompletions module
- Use FallbackController pattern for error handling
- Validate at the controller boundary (string-to-atom, required fields)
