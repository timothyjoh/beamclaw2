# Phase 2: Agent Lifecycle — Reflections

## What Went Well

### Fast Execution
Phase 2 completed in ~15 minutes total (docs + build + tests). Applied Phase 1 lesson: timeboxed research, wrote docs first, built sequentially.

### Clean OTP Patterns
Used standard Elixir/OTP patterns throughout:
- `DynamicSupervisor` for dynamic child management
- `Registry` for process name registration (auto-cleanup on death)
- GenServer for per-agent state
- Facade pattern (`AgentManager`) for clean public API

### No External Dependencies
Everything built with OTP stdlib. UUID generation uses `:crypto.strong_rand_bytes/16` — no need for a UUID library.

### 23 New Tests, All Passing
- 9 tests for `Agent` struct (construction, transitions, validation)
- 6 tests for `AgentServer` (start, get, update, not_found)
- 8 tests for `AgentManager` (CRUD, lifecycle integration)
- All 16 Phase 1 tests still passing (39 total)

## What Didn't Go Well

### Race Condition After Process Termination
Initial implementation of `stop_agent` + `get_agent` had a race: Registry lookup could return a pid that was already dead. Fixed by wrapping `GenServer.call` in `try/catch :exit`. Same defensive pattern needed in `list_agents` (used `flat_map` to skip dead processes).

**Lesson**: Always handle `{:EXIT, _}` when calling processes that might be terminated. Registry cleanup is async.

### UUID Generation Needed `import Bitwise`
Forgot to import Bitwise for bit operations in UUID v4 generation. Minor but caught by compilation.

## Architectural Decisions

1. **`:temporary` restart strategy**: Agents don't auto-restart on crash. Intentional — the caller should decide how to handle agent failure. This matches the "agent lifecycle management" model.

2. **Registry over ETS**: Registry auto-cleans entries when processes die. ETS would require manual cleanup. Worth the tradeoff.

3. **Facade pattern**: `AgentManager` wraps supervisor + registry + genserver. Callers never need to know about process internals.

4. **Agent struct separate from GenServer**: `Beamclaw2.Agent` is pure data; `AgentServer` is the process. Clean separation of concerns.

## Carry-Forward for Phase 3

- REST API endpoints for agents (create, get, list, update, stop)
- The `AgentManager` API maps cleanly to REST verbs
- Consider: should `stop_agent` set status to `:stopped` before terminating? Currently it just terminates. Status transition is lost.

## Metrics
- **Time**: ~15 minutes
- **Tests**: 39 total (23 new), 0 failures
- **Warnings**: 0
- **New modules**: 4 (`Agent`, `AgentServer`, `AgentSupervisor`, `AgentManager`)
