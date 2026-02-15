# BeamClaw — Project Brief

## Vision

Build a production-quality reimplementation of OpenClaw on BEAM/OTP, leveraging Erlang's structural advantages for AI agent orchestration.

## Why BEAM?

AI eliminates Elixir's two historical barriers: hiring difficulty and small ecosystem. What remains is BEAM's structural advantages for agents:

- **Fault tolerance** — supervisor trees mean one crashed agent doesn't take down the system
- **Millions of lightweight processes** — every agent session, every tool call, every channel connection = its own process
- **Supervision trees** — self-healing architecture built into the runtime
- **Hot code reloading** — update agent behavior without dropping connections
- **Built-in distribution** — agents running across multiple nodes, natively
- **Process mailboxes** — message queuing is free, no external queue needed

## Source Reference

OpenClaw source code lives at `~/wrk/opc/openclaw/` (~311K lines TypeScript, ~1700 files).

Key directories to study:
- `src/gateway/` — the main daemon
- `src/agents/` — agent lifecycle and configuration
- `src/sessions/` — conversation sessions and history
- `src/channels/` — Discord, Telegram, etc.
- `src/cron/` — scheduled jobs
- `src/infra/` — tools, exec, browser control
- `src/providers/` — LLM provider routing (Anthropic, OpenAI, etc.)

## Goals

1. **Feature parity** with OpenClaw's core agent loop (config → session → provider → response)
2. **BEAM-native architecture** — not a port, a reimagining using OTP patterns
3. **Multi-tenant from day one** — each tenant gets isolated supervision trees
4. **Observable** — telemetry, LiveDashboard, production-ready monitoring
5. **Distributable** — designed to run across multiple BEAM nodes

## Non-Goals (for now)

- Full plugin/skill ecosystem compatibility
- Every channel adapter (start with Discord)
- Browser automation tooling
- UI/frontend

## This Document

This BRIEF.md is the project constitution. It only changes if Butter and Rita explicitly agree to modify it. Everything else — the plan, the phases, the architecture — is derived from this and can evolve.
