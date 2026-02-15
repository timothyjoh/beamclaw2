# Phase 2: Research Notes

## Existing Codebase (Phase 1)
- Phoenix app: `beamclaw2`, module prefix `Beamclaw2`
- Supervision tree in `Beamclaw2.Application` with `Beamclaw2.Supervisor` (one_for_one)
- Children: Telemetry, DNSCluster, PubSub, Endpoint
- 16 tests passing, JSON logging, health endpoint at `/health`

## OTP Patterns for Dynamic Agents

### DynamicSupervisor
- Perfect for spawning variable number of child processes at runtime
- `start_child/2` to add, `terminate_child/2` to remove
- Use `:temporary` restart strategy — crashed agents shouldn't auto-restart (we want explicit lifecycle control)

### Registry
- Built-in Elixir `Registry` for process name registration
- `{:via, Registry, {Beamclaw2.AgentRegistry, agent_id}}` for GenServer name
- Provides `Registry.lookup/2` for finding processes by key
- `Registry.select/2` for listing all registered processes

### GenServer for Agent State
- Each agent is a GenServer holding an `%Agent{}` struct
- `handle_call` for sync operations (get_state, update_status)
- `handle_cast` for async operations (if needed later)
- `terminate/2` callback for cleanup logging

## Key Decisions
1. **Registry over ETS**: Registry is process-aware (auto-cleans dead processes), simpler API
2. **`:temporary` restart**: Agents don't restart on crash — the caller should decide what to do
3. **Facade pattern**: `AgentManager` module wraps DynamicSupervisor + Registry + GenServer calls for clean API
4. **UUID v4**: Use built-in `:crypto.strong_rand_bytes/1` or a simple UUID generator (no dep needed — Ecto.UUID or manual)

## No External Dependencies Needed
Everything uses OTP stdlib: GenServer, DynamicSupervisor, Registry. UUID can be generated with `:crypto`.
