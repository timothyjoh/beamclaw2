---
date: 2026-02-15T18:57:00Z
phase: phase-3-rest-api
status: ready
---

# Implementation Plan: phase-3-rest-api

## Overview
Add 5 REST endpoints for agent CRUD under `/api/agents`, with JSON serialization, input validation, error handling, and comprehensive tests.

## Desired End State
- `POST /api/agents` creates an agent, returns 201
- `GET /api/agents` lists all agents, returns 200
- `GET /api/agents/:id` returns agent, 200 or 404
- `PATCH /api/agents/:id` updates status, returns 200 or 422
- `DELETE /api/agents/:id` stops agent, returns 204 or 404
- stop_agent sets :stopped status before termination
- All errors return consistent `{"error": {"message": "..."}}` format

## What We're NOT Doing
- Authentication, pagination, WebSocket updates
- Task execution endpoints

---

## Task 1: JSON Serialization + Agent Stop Fix

### Changes
1. **Agent struct** — derive Jason.Encoder, convert atoms/datetimes for JSON
2. **AgentJSON view** — `lib/beamclaw2_web/controllers/agent_json.ex` — transforms Agent to map
3. **AgentManager.stop_agent/1** — transition to :stopped before terminating

---

## Task 2: FallbackController + AgentController

### Changes
1. **FallbackController** — handles `{:error, :not_found}`, `{:error, :invalid_transition}`, `{:error, :invalid_params}`
2. **AgentController** — 5 actions: create, index, show, update, delete
3. **Router** — add `resources "/agents", AgentController, except: [:new, :edit]`

---

## Task 3: Controller Tests

### Tests
- Create agent (201, with/without name)
- List agents (200, empty and non-empty)
- Get agent (200, 404)
- Update status (200, 404, 422 invalid transition)
- Delete/stop agent (204, 404)
- Invalid create params (422)
