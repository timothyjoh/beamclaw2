# Phase 1: Foundation — Research

## 1. OpenClaw Bootstrap Analysis

OpenClaw's startup is a multi-stage chain: `entry.ts` normalizes the environment (argv, color settings, Node warnings), then conditionally respawns the process with suppressed experimental warnings before importing `cli/run-main.js`. The gateway boot (`gateway/boot.ts`) loads a `BOOT.md` file from the workspace, constructs a prompt from it, resolves a session key, and runs an agent command — essentially using the AI to execute startup tasks. This is a creative but fragile pattern; the boot process depends on the AI provider being available.

For BeamClaw2, we get all of this for free from OTP. `Application.start/2` is our entry point, the supervision tree defines startup order declaratively, and there's no need for process respawning or argv normalization. The BEAM VM handles signal trapping, graceful shutdown, and process lifecycle natively. We should adopt OpenClaw's concept of a structured boot sequence (logging "started" / "stopping" messages) but reject the complexity of self-respawning and AI-driven boot tasks.

## 2. Configuration Patterns

OpenClaw uses a `config.ts` module with TypeScript types defining the config schema, environment variable overrides via `infra/env.ts` (`normalizeEnv()`), and CLI profile support (`cli/profile.ts`) that applies env vars based on named profiles. Config values are accessed through a typed config object passed through the call chain.

For BEAM, we should use Elixir's built-in config system (`config/runtime.exs`) which already handles environment-specific config and runtime env var reading. A `Config.Server` GenServer is overkill for Phase 1 — `Application.get_env/3` is sufficient and idiomatic. If we need runtime config changes later, we can add a GenServer then. Environment variable overrides should follow the `BEAMCLAW_*` prefix convention from the SPEC. We should avoid building a custom config loader or profile system; Elixir's Mix environments (`dev`, `test`, `prod`) cover this natively.

## 3. Logging Approach

OpenClaw's logging (`logger.ts`) uses a dual-output pattern: console output via runtime functions (`logInfo`, `logWarn`, etc.) and file output via `getLogger()`. It supports subsystem-prefixed messages (e.g., `"gateway/boot: message"`) parsed via regex to route logs to subsystem-specific loggers. The `createSubsystemLogger` function creates scoped loggers with a subsystem tag. Debug output goes to file always but console only when verbose mode is enabled.

Elixir's Logger already provides structured metadata, configurable backends, and level filtering — no custom framework needed. For JSON structured logging, we should configure a JSON formatter (either custom or via `logger_json` hex package) on the default Logger handler. Subsystem tagging maps cleanly to Logger metadata: `Logger.info("started", subsystem: "gateway")`. The SPEC calls for JSON output with `timestamp`, `level`, `message`, `module`, `function` — Logger's default metadata already captures `module`, `function`, and `line`. We write a simple `JSONFormatter` module that formats Logger events as JSON maps.

## 4. Recommendations for Phase 1

**Use Phoenix, not raw Plug.Cowboy.** The SPEC suggests minimal Plug.Cowboy, but we already have a Phoenix app generated (from the earlier setup). Phoenix adds negligible overhead and gives us routing, telemetry integration, and a clear path to LiveDashboard in Phase 8. The health endpoint becomes a simple controller action rather than a raw Plug module. This is a pragmatic deviation from the SPEC that pays dividends in later phases.

**Keep the supervision tree minimal.** Phase 1 needs: `Telemetry` (already there from Phoenix), `PubSub` (already there), `Endpoint` (already there). A `Config.Server` GenServer is unnecessary — `Application.get_env/3` covers Phase 1's needs. Add it later when we need runtime config reloading. The top-level supervisor should use `one_for_one` strategy (already configured).

**JSON logging via custom formatter.** Write a `Beamclaw2.Logger.JSONFormatter` module that implements `Logger.Formatter` behaviour. Configure it in `config.exs`. This satisfies the SPEC's structured logging requirement without adding dependencies. Support `BEAMCLAW_LOG_LEVEL` env var in `config/runtime.exs` to override the log level.

## 5. Risks & Gotchas

**App name mismatch.** The SPEC uses `:beam_claw` as the app name and `BeamClaw` as the module prefix, but the generated Phoenix app uses `:beamclaw2` and `Beamclaw2`. We need to pick one and stay consistent. Recommendation: keep `:beamclaw2` / `Beamclaw2` since that's what's generated and matches the project name. Update the SPEC mentally but don't fight the tooling.

**Phoenix vs. Plug.Cowboy.** The SPEC says "Minimal Plug.Cowboy setup (no Phoenix yet)" but we've already generated a Phoenix app with Bandit (not Cowboy). This is actually better — Bandit is the modern default, Phoenix gives us structure. The risk is scope creep; we must resist adding Phoenix features beyond what Phase 1 needs (health endpoint, config, logging).

**Test environment port conflicts.** Phoenix tests use a random port by default (good), but if we add integration tests that hit the endpoint, we need to ensure `Beamclaw2Web.Endpoint` is started in the test setup. Phoenix.ConnTest handles this via `@endpoint` — use it rather than starting a real HTTP server in tests.
