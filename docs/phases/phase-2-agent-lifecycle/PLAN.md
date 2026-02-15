# Phase 2: Build Plan

## Task Order (sequential, commit after each)

### Task 1: Agent Data Struct
- Create `lib/beamclaw2/agent.ex` — `%Beamclaw2.Agent{}` struct
- Fields: `id`, `name`, `status`, `metadata`, `created_at`, `updated_at`
- Status values: `:initializing`, `:idle`, `:running`, `:completed`, `:failed`, `:stopped`
- Add `valid_transition?/2` function for status state machine
- Add `new/1` constructor that generates UUID and sets timestamps
- Write tests in `test/beamclaw2/agent_test.exs`

### Task 2: AgentServer GenServer
- Create `lib/beamclaw2/agent_server.ex`
- `start_link/1` takes agent params, registers via Registry
- `init/1` creates `%Agent{}` struct as state
- `handle_call(:get_state, ...)` returns current state
- `handle_call({:update_status, new_status}, ...)` validates and transitions
- `terminate/2` logs shutdown
- Write tests in `test/beamclaw2/agent_server_test.exs`

### Task 3: Registry + DynamicSupervisor
- Add `Beamclaw2.AgentRegistry` (Registry) to Application children
- Create `lib/beamclaw2/agent_supervisor.ex` — DynamicSupervisor
- Add to Application children (after Registry)
- Write tests for supervisor start/child management

### Task 4: AgentManager Facade
- Create `lib/beamclaw2/agent_manager.ex`
- `create_agent/1` — starts child under DynamicSupervisor
- `get_agent/1` — looks up via Registry, calls GenServer
- `list_agents/0` — uses Registry.select to get all agent pids, queries each
- `stop_agent/1` — updates status to :stopped, terminates child
- `update_status/2` — delegates to GenServer
- Write tests in `test/beamclaw2/agent_manager_test.exs`

### Task 5: Integration Tests + Cleanup
- Integration test: create → get → update → list → stop → verify not found
- Verify all 16 original tests still pass
- `mix compile --warnings-as-errors`
- `mix format --check-formatted`
- Final commit

## Verification
```bash
mix test
mix compile --warnings-as-errors
mix format --check-formatted
```
