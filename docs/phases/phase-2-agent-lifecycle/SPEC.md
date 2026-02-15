# Phase 2: Agent Lifecycle — GenServer + Supervisor

## Goal

Implement GenServer-based agent lifecycle management with proper OTP supervision. Agents can be created, queried, and stopped. Each agent is a supervised GenServer process with state tracking.

## What is an "Agent" in BeamClaw?

An agent is a lightweight, supervised process that represents a unit of work or an AI agent session. It has:
- A unique ID (UUID)
- A name
- A status lifecycle: `:initializing` → `:idle` → `:running` → `:completed` | `:failed` | `:stopped`
- Timestamps (created_at, updated_at)
- Metadata map for extensibility

## Architecture

```
Beamclaw2.Supervisor (existing, one_for_one)
  ├── Beamclaw2Web.Telemetry (existing)
  ├── DNSCluster (existing)
  ├── Phoenix.PubSub (existing)
  ├── Beamclaw2Web.Endpoint (existing)
  ├── Beamclaw2.AgentRegistry (Registry for name-based lookup)
  └── Beamclaw2.AgentSupervisor (DynamicSupervisor)
        ├── Beamclaw2.AgentServer (GenServer, per-agent)
        ├── Beamclaw2.AgentServer (GenServer, per-agent)
        └── ...
```

## Modules

### `Beamclaw2.Agent` — Data struct
Pure data struct defining agent state. No process logic.

### `Beamclaw2.AgentServer` — GenServer
Per-agent process. Holds agent state, handles status transitions, responds to queries.

### `Beamclaw2.AgentSupervisor` — DynamicSupervisor  
Manages dynamic creation/termination of AgentServer processes.

### `Beamclaw2.AgentRegistry` — Registry
Allows lookup of agents by ID. Uses Elixir's built-in `Registry`.

### `Beamclaw2.AgentManager` — Public API
Facade module that orchestrates creating, listing, getting, and stopping agents. This is what controllers and other modules call.

## Acceptance Criteria

### AC1: Create Agent
**Given** the application is running  
**When** I call `AgentManager.create_agent(%{name: "test-agent"})`  
**Then** a new AgentServer process starts under AgentSupervisor  
**And** it returns `{:ok, %Agent{status: :initializing}}`  
**And** the agent has a UUID id

### AC2: Get Agent State
**Given** an agent exists with id "abc-123"  
**When** I call `AgentManager.get_agent("abc-123")`  
**Then** it returns `{:ok, %Agent{id: "abc-123", ...}}`

### AC3: List Agents
**Given** 3 agents are running  
**When** I call `AgentManager.list_agents()`  
**Then** it returns a list of 3 `%Agent{}` structs

### AC4: Stop Agent
**Given** an agent exists with id "abc-123"  
**When** I call `AgentManager.stop_agent("abc-123")`  
**Then** the agent status transitions to `:stopped`  
**And** the GenServer process terminates cleanly

### AC5: Status Transitions
**Given** an agent in `:initializing` status  
**When** I call `AgentManager.update_status("abc-123", :idle)`  
**Then** the agent status changes to `:idle`  
**And** `updated_at` timestamp is refreshed  
Invalid transitions return `{:error, :invalid_transition}`

### AC6: Crash Recovery
**Given** an agent GenServer crashes  
**Then** the DynamicSupervisor does NOT restart it (`:temporary` strategy)  
**And** the crash is logged

### AC7: Not Found Handling
**Given** no agent with id "nonexistent"  
**When** I call `AgentManager.get_agent("nonexistent")`  
**Then** it returns `{:error, :not_found}`

### AC8: Tests Pass
- All new tests pass
- All existing 16 tests still pass
- `mix compile --warnings-as-errors` clean
- `mix format --check-formatted` clean

## Out of Scope
- REST API endpoints for agents (Phase 3)
- Persistence/database (Phase 4)
- Agent communication/messaging (Phase 5)
- Task execution within agents (later)
