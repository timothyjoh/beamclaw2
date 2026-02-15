---
date: 2026-02-15T18:57:00Z
phase: phase-3-rest-api
phase_number: 3
phase_name: "REST API — Agent CRUD Endpoints"
status: ready
---

# Phase 3: REST API — Agent CRUD Endpoints

## Objective
Expose the AgentManager facade as RESTful JSON endpoints, enabling external clients to create, read, list, update, and stop agents over HTTP.

## Scope

### In Scope
- `POST /api/agents` — create agent
- `GET /api/agents` — list all agents
- `GET /api/agents/:id` — get agent by ID
- `PATCH /api/agents/:id` — update agent status
- `DELETE /api/agents/:id` — stop agent
- JSON serialization of Agent struct
- Input validation and error responses
- Controller tests (ConnCase)
- FallbackController for consistent error handling
- Address Phase 2 carry-forward: stop_agent should set status to :stopped before terminating

### Out of Scope
- Authentication/authorization
- Pagination for list endpoint
- WebSocket/SSE for real-time updates
- Agent task execution endpoints

## Requirements
- All endpoints return JSON
- Proper HTTP status codes (201, 200, 204, 404, 422)
- Input validation on create (name required) and update (valid status)
- Consistent error response format: `{"error": {"message": "..."}}`

## Acceptance Criteria
- [ ] All 5 CRUD endpoints work correctly
- [ ] Agent struct serializes to JSON (via Jason.Encoder or view module)
- [ ] 404 returned for non-existent agent IDs
- [ ] 422 returned for invalid input (bad status, missing name)
- [ ] stop_agent transitions to :stopped before terminating
- [ ] All tests pass (mix test)
- [ ] Code compiles without warnings
- [ ] Code formatted

## Dependencies
- Phase 2: AgentManager, Agent struct, AgentServer, AgentSupervisor

## Adjustments from Previous Phase
- From Phase 2 reflections: handle race conditions on process termination (already handled in AgentManager with try/catch)
- From Phase 2 carry-forward: implement :stopped status transition in stop_agent before termination
