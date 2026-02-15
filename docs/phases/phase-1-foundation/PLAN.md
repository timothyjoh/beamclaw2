# Phase 1: Foundation — Build Plan

## Context

Phoenix app skeleton is already generated. Research shows we should embrace Phoenix rather than fight it, use built-in Logger with custom JSON formatter, and keep supervision tree minimal.

## Tasks

### Task 1: Configure JSON Logging
**Owner**: Implementor A  
**Dependencies**: None  
**Deliverable**: `lib/beamclaw2/logger/json_formatter.ex`

1. Create `Beamclaw2.Logger.JSONFormatter` module
2. Implement `format/4` callback returning JSON string
3. Include fields: `timestamp` (ISO8601), `level`, `message`, `module`, `function`, `line`, `pid`
4. Configure in `config/config.exs`:
   ```elixir
   config :logger, :default_handler,
     formatter: {Beamclaw2.Logger.JSONFormatter, []}
   ```
5. Add `BEAMCLAW_LOG_LEVEL` env var support in `config/runtime.exs`
6. Write unit tests for formatter output

### Task 2: Health Endpoint
**Owner**: Implementor B  
**Dependencies**: None  
**Deliverable**: `lib/beamclaw2_web/controllers/health_controller.ex`

1. Create `Beamclaw2Web.HealthController`
2. Implement `index/2` action returning:
   ```json
   {"status": "ok", "timestamp": "2026-02-15T18:40:00Z"}
   ```
3. Add route in `router.ex`: `get "/health", HealthController, :index`
4. Set Content-Type to `application/json`
5. Write integration test using `conn` helper

### Task 3: Application Lifecycle Logging
**Owner**: Implementor A  
**Dependencies**: Task 1 (logging configured)  
**Deliverable**: `lib/beamclaw2/application.ex` (updated)

1. Add Logger call in `start/2`: `Logger.info("BeamClaw2 started", subsystem: "application")`
2. Add Logger call in hypothetical `stop/1`: `Logger.info("BeamClaw2 stopping", subsystem: "application")`
   - Note: `stop/1` is optional in Application behavior, document that SIGTERM triggers shutdown without explicit callback
3. Verify logs output JSON format on startup

### Task 4: Configuration Validation
**Owner**: Implementor B  
**Dependencies**: None  
**Deliverable**: `config/runtime.exs` (updated)

1. Read `BEAMCLAW_HTTP_PORT` env var (default 4000)
2. Read `BEAMCLAW_LOG_LEVEL` env var (default :info)
3. Read `BEAMCLAW_ENV` env var (default Mix.env())
4. Configure `Beamclaw2Web.Endpoint` port from `BEAMCLAW_HTTP_PORT`
5. Log clear error if required config missing (none required in Phase 1, but establish pattern)

### Task 5: Unit Tests (Health + Config)
**Owner**: Unit Tester  
**Dependencies**: Task 2, Task 4  
**Deliverables**: `test/beamclaw2_web/controllers/health_controller_test.exs`, `test/beamclaw2/config_test.exs`

1. Test health endpoint returns 200 OK
2. Test health endpoint JSON structure
3. Test config loading with env vars set
4. Test config fallback to defaults
5. Verify all tests in `test/` directory pass

### Task 6: E2E Test (Full Lifecycle)
**Owner**: E2E Tester  
**Dependencies**: All above  
**Deliverable**: `test/beamclaw2/e2e/application_lifecycle_test.exs`

1. Test: Application starts successfully
2. Test: Health endpoint responds correctly
3. Test: Logs are valid JSON (capture Logger output in test)
4. Test: Env var overrides work (set `BEAMCLAW_LOG_LEVEL=debug`, verify Logger level)
5. Test: Application can be stopped cleanly (via `Application.stop(:beamclaw2)`)

### Task 7: Documentation
**Owner**: Implementor A  
**Dependencies**: All above  
**Deliverable**: README updates, inline docs

1. Update README with "Getting Started" section
2. Document env vars (`BEAMCLAW_HTTP_PORT`, `BEAMCLAW_LOG_LEVEL`, `BEAMCLAW_ENV`)
3. Add `@moduledoc` to all new modules
4. Run `mix format` on all files
5. Run `mix compile --warnings-as-errors` and fix warnings

## Acceptance Criteria Mapping

- **AC1 (Lifecycle)** → Task 3, Task 6
- **AC2 (Config)** → Task 4, Task 5
- **AC3 (Logging)** → Task 1, Task 6
- **AC4 (Health)** → Task 2, Task 5
- **AC5 (Shutdown)** → Task 6
- **AC6 (Tests)** → Task 5, Task 6

## Team Structure

- **Implementor A** (primary): JSON logging, application lifecycle, docs
- **Implementor B** (primary): Health endpoint, config validation
- **Unit Tester**: Test all units individually
- **E2E Tester**: Integration test full app lifecycle

## Success Criteria

```bash
$ mix compile --warnings-as-errors  # passes
$ mix test                           # all green
$ mix format --check-formatted       # passes
$ mix run --no-halt                  # starts, logs "BeamClaw2 started" in JSON
$ curl http://localhost:4000/health  # returns {"status": "ok", "timestamp": "..."}
```

## Notes

- Phoenix app already exists, embrace it
- Bandit (not Cowboy) is Phoenix default in Elixir 1.17+, that's fine
- No `Config.Server` GenServer needed — `Application.get_env/3` sufficient
- JSON formatter is ~30 lines of code, no external deps needed
