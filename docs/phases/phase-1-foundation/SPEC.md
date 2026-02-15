# Phase 1: Foundation — Application Bootstrap

## Goal

Establish the OTP application structure, configuration system, and logging infrastructure. This is the bedrock on which all other phases build.

## Architecture Decisions

### Application Structure
- **Type**: Standard OTP application with Application callback
- **Supervision Strategy**: `one_for_one` at top level (single child: main supervisor)
- **Entry Point**: `BeamClaw.Application.start/2`

### Configuration System
- **Source**: `config/runtime.exs` for runtime configuration
- **Environment Variables**: Support `BEAMCLAW_*` prefix for overrides
- **Format**: Keyword lists, not external YAML (keep it simple for Phase 1)
- **Reloadability**: Not in Phase 1 (hot reload comes later)

### Logging
- **Backend**: Standard Elixir Logger
- **Format**: JSON structured logging (production-ready from day one)
- **Levels**: Configurable via `BEAMCLAW_LOG_LEVEL` env var
- **Metadata**: Always include: `timestamp`, `level`, `message`, `module`, `function`

### Health Check
- **Endpoint**: `GET /health`
- **Response**: `{"status": "ok", "timestamp": "2026-02-15T18:34:00Z"}`
- **Server**: Minimal Plug.Cowboy setup (no Phoenix yet)

## Acceptance Criteria

### AC1: Application Lifecycle
**Given** the BeamClaw application is not running  
**When** I run `mix run --no-halt`  
**Then** the application starts successfully  
**And** the top-level supervisor is running  
**And** logs show "BeamClaw started" message

### AC2: Configuration Loading
**Given** a config file exists at `config/runtime.exs`  
**When** the application starts  
**Then** configuration values are accessible via `Application.get_env(:beam_claw, :key)`  
**And** environment variables override config file values  
**And** missing required config triggers clear error message

### AC3: Structured Logging
**Given** the application is running  
**When** a log message is emitted at any level  
**Then** the output is valid JSON  
**And** includes timestamp, level, message, module, function  
**And** log level respects `BEAMCLAW_LOG_LEVEL` environment variable

### AC4: Health Check Endpoint
**Given** the application is running  
**When** I send `GET http://localhost:4000/health`  
**Then** I receive HTTP 200 OK  
**And** response body is `{"status": "ok", "timestamp": "<ISO8601>"}`  
**And** response Content-Type is `application/json`

### AC5: Clean Shutdown
**Given** the application is running  
**When** I send SIGTERM or SIGINT  
**Then** the application shuts down gracefully  
**And** logs show "BeamClaw stopping" message  
**And** all supervised processes terminate cleanly

### AC6: Test Coverage
**Given** all code is written  
**When** I run `mix test`  
**Then** all tests pass  
**And** code coverage is ≥80%  
**And** tests include: application start/stop, config loading, health endpoint

## Non-Functional Requirements

- **Boot Time**: Application starts in <2 seconds
- **Memory**: Base memory footprint <50MB (measured via `:observer.start()`)
- **Dependencies**: Minimal (Plug.Cowboy, Jason for JSON, that's it)

## Out of Scope (Deferred to Later Phases)

- Agent supervision (Phase 2)
- Database/persistence (Phase 4)
- Phoenix LiveView/LiveDashboard (Phase 8)
- Hot code reloading (post-MVP)
- Distributed node setup (post-MVP)

## Technical Implementation Notes

### Mix Project Setup
```elixir
# mix.exs
def project do
  [
    app: :beam_claw,
    version: "0.1.0",
    elixir: "~> 1.17",
    start_permanent: Mix.env() == :prod,
    deps: deps()
  ]
end

def application do
  [
    extra_applications: [:logger],
    mod: {BeamClaw.Application, []}
  ]
end
```

### Supervision Tree (Phase 1)
```
BeamClaw.Application
  └── BeamClaw.Supervisor (one_for_one)
        └── {Plug.Cowboy, scheme: :http, plug: BeamClaw.HealthPlug, port: 4000}
```

### Configuration Keys
- `:beam_claw, :http_port` - HTTP server port (default: 4000)
- `:beam_claw, :log_level` - Logger level (default: :info)
- `:beam_claw, :env` - Environment (:dev | :test | :prod)

### Logger Configuration
```elixir
config :logger, :default_formatter,
  format: {BeamClaw.Logger.JSONFormatter, :format},
  metadata: [:module, :function, :line, :pid]
```

## Dependencies

```elixir
defp deps do
  [
    {:plug_cowboy, "~> 2.7"},
    {:jason, "~> 1.4"}
  ]
end
```

## Testing Strategy

### Unit Tests
- `BeamClaw.Application` start/stop behavior
- `BeamClaw.Config` loading and env var override
- `BeamClaw.Logger.JSONFormatter` output format

### Integration Tests
- Full app start → health check → graceful shutdown
- Config file loading → verify values accessible
- Log level override via env var

### Property Tests
- None for Phase 1 (not enough complexity to justify)

## Success Metrics

- **Compiles**: `mix compile` succeeds with zero warnings
- **Tests Pass**: `mix test` all green
- **Runs**: `mix run --no-halt` starts and stays running
- **Responds**: `curl http://localhost:4000/health` returns 200 OK
- **Stops Cleanly**: SIGTERM triggers graceful shutdown

## Open Questions

None. This phase is straightforward OTP boilerplate.

## Dependencies on Previous Phases

None (this is Phase 1).

## Blocks Future Phases

All future phases depend on this foundation.

---

**Review Checklist (for Codex CLI)**
- [ ] All acceptance criteria have corresponding tests
- [ ] Health endpoint responds correctly
- [ ] Logs are valid JSON
- [ ] Config loading handles missing values gracefully
- [ ] Shutdown is graceful (no orphaned processes)
- [ ] No compiler warnings
- [ ] Credo/Dialyzer pass (if configured)
