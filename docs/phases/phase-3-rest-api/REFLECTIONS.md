# Phase 3: REST API — Reflections

## What Went Well

### Clean Mapping from AgentManager to REST
The facade pattern from Phase 2 paid off perfectly. Each AgentManager function mapped 1:1 to a controller action:
- `create_agent/1` → `POST /api/agents`
- `list_agents/0` → `GET /api/agents`
- `get_agent/1` → `GET /api/agents/:id`
- `update_status/2` → `PATCH /api/agents/:id`
- `stop_agent/1` → `DELETE /api/agents/:id`

### FallbackController Pattern
Phoenix's `action_fallback` keeps controller actions clean — they just return `{:error, reason}` tuples and the fallback handles HTTP status codes. Worth using from the start.

### Phase 2 Carry-Forward Resolved
Implemented :stopped status transition before termination in `stop_agent`. The try/catch handles the case where the process dies between status update and termination.

## What Didn't Go Well
Nothing significant. This was the most straightforward phase — the hard OTP work was Phase 2.

## Architectural Decisions

1. **AgentJSON view module over Jason.Encoder**: Explicit view gives us control over serialization without polluting the domain struct. Atoms become strings, DateTimes become ISO8601 strings at the boundary.

2. **FallbackController for errors**: Consistent error format `{"error": {"message": "..."}}` across all endpoints. Easy to extend for new error types.

3. **String-to-atom validation at controller boundary**: Status strings are validated against a whitelist before `String.to_existing_atom/1`. No arbitrary atom creation from user input.

4. **204 No Content for DELETE**: Standard REST convention — successful deletion returns empty body.

## Metrics
- **Time**: ~10 minutes
- **Tests**: 54 total (15 new), 0 failures
- **Warnings**: 0
- **New modules**: 3 (AgentController, AgentJSON, FallbackController)

## Carry-Forward for Phase 4
- WebSocket/SSE for real-time agent status updates
- Authentication/authorization layer
- Pagination for list endpoint (when agent count grows)
- Agent task execution — assigning work to agents via API
- Consider adding `GET /api/agents/:id/logs` for agent event history
