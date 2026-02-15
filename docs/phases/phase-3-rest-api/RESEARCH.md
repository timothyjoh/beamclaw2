---
date: 2026-02-15T18:57:00Z
phase: phase-3-rest-api
status: complete
---

# Research: phase-3-rest-api

## Phase Context
Add REST API endpoints for agent CRUD operations, mapping AgentManager's existing API to HTTP verbs.

## Previous Phase Learnings
- Race conditions after process termination handled via try/catch :exit in AgentManager
- stop_agent currently just terminates — should set :stopped status first
- AgentManager API maps cleanly to REST verbs

## Current Codebase State

### Relevant Components
- **Router**: `lib/beamclaw2_web/router.ex` — has `/api` scope with `:api` pipeline, currently empty. Health endpoint is outside scope.
- **HealthController**: `lib/beamclaw2_web/controllers/health_controller.ex` — pattern: `use Beamclaw2Web, :controller`, returns JSON via `json/2`
- **ErrorJSON**: `lib/beamclaw2_web/controllers/error_json.ex` — exists for default error rendering
- **AgentManager**: `lib/beamclaw2/agent_manager.ex` — facade with create_agent/1, get_agent/1, list_agents/0, update_status/2, stop_agent/1
- **Agent struct**: `lib/beamclaw2/agent.ex` — has id, name, status (atom), metadata (map), created_at, updated_at (DateTime)
- **ConnCase**: `test/support/conn_case.ex` — test helper with Phoenix.ConnTest setup

### Existing Patterns
- Controllers use `use Beamclaw2Web, :controller` and `json/2` for responses
- No FallbackController yet — HealthController handles responses inline
- No JSON encoding for Agent struct — needs Jason.Encoder implementation or a JSON view
- Agent status is an atom — needs string conversion for JSON

### Key Design Decisions Needed
1. **JSON serialization**: Derive Jason.Encoder on Agent struct vs. explicit view/JSON module
2. **Error handling**: FallbackController vs. inline pattern matching in each action
3. **Status conversion**: Atoms ↔ strings at the controller boundary

### Test Infrastructure
- ExUnit with Phoenix.ConnCase
- `build_conn()` available for HTTP test requests
- Existing controller test pattern in health_controller_test.exs
