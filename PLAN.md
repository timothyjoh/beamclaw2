# BeamClaw2 - Build Plan

## Architecture Mapping: Node.js → BEAM

### Core Translation Patterns

| OpenClaw (Node.js) | BeamClaw2 (BEAM/OTP) | Rationale |
|-------------------|----------------------|-----------|
| Express HTTP server | Cowboy/Bandit (Phoenix) | Production-grade HTTP/WS, built for BEAM |
| Agent instance | GenServer per agent | Lightweight process, mailbox for message queue |
| Session state | GenServer + ETS/Mnesia | Hot state in process, persistence in ETS/Mnesia |
| Provider API client | GenServer pool (Poolboy/Finch) | Connection pooling, rate limiting, fault tolerance |
| Channel adapter | GenServer per connection | Isolated failure domain per channel |
| Tool execution | Task + Registry | Async execution, trackable via process registry |
| Cron scheduler | Quantum or custom Supervisor | Built-in distribution, fault tolerance |
| Config reload | Hot code reloading | BEAM native - update without restart |
| Multi-tenant isolation | Supervision tree per tenant | Self-healing, resource isolation |

### Key BEAM Advantages We're Leveraging

1. **Fault tolerance** - Supervisor trees restart crashed agents without system-wide impact
2. **Concurrency** - Million+ lightweight processes (agent per user, session per conversation)
3. **Distribution** - Native clustering (agents running across nodes)
4. **Hot reload** - Update agent behavior without dropping connections
5. **Message passing** - Process mailboxes = free message queuing
6. **Observability** - Built-in telemetry, tracing, LiveDashboard

---

## Phase Breakdown

Each phase is a **vertical slice** delivering a testable, demonstrable capability.

### Phase 1: Foundation — Application Bootstrap

**Goal**: Establish the OTP application structure, configuration system, and logging.

**Deliverables**:
- Mix project with supervision tree
- Configuration loading (config/runtime.exs)
- Structured logging (Logger integration)
- Basic health check endpoint
- Tests proving app starts/stops cleanly

**Success Criteria**:
- `mix run` starts the application
- Configuration loads from files and environment variables
- Logs output in structured JSON format
- Health endpoint returns 200 OK

**Architecture**: Standard OTP app with Application callback, top-level supervisor.

---

### Phase 2: Agent Lifecycle — GenServer + Supervisor

**Goal**: Implement agent as GenServer with supervisor tree, load config from YAML.

**Deliverables**:
- `AgentServer` GenServer (manages single agent instance)
- `AgentSupervisor` DynamicSupervisor (starts/stops agents)
- Agent config loader (YAML → Elixir struct)
- Agent registry (track running agents by ID)
- Tests for agent start/stop/restart

**Success Criteria**:
- Agent starts from config file
- Agent crashes → supervisor restarts it
- Can query agent state via Registry
- Config changes trigger agent reload

**Architecture**: DynamicSupervisor managing AgentServer processes, registered via Registry.

---

### Phase 3: Provider Integration — Anthropic API Client

**Goal**: Call Anthropic API, stream responses, handle errors and retries.

**Deliverables**:
- `Providers.Anthropic` module (HTTP client using Finch)
- Streaming response parser (SSE → Elixir messages)
- Error handling + exponential backoff
- Rate limiting (per-key token bucket)
- Tests with mocked API responses

**Success Criteria**:
- Send message → receive streaming response
- Rate limit prevents over-calling API
- Transient errors trigger retry
- Auth errors bubble up clearly

**Architecture**: Finch pool for HTTP connections, GenServer for rate limiting state.

---

### Phase 4: Session Management — Conversation State

**Goal**: Persist and retrieve conversation history, support multiple concurrent sessions.

**Deliverables**:
- `SessionServer` GenServer (manages single conversation)
- Session persistence (ETS + periodic disk write)
- Message history compaction (limit context window)
- Session registry (lookup by session ID)
- Tests for session CRUD operations

**Success Criteria**:
- Create session → add messages → retrieve history
- Sessions persist across app restart
- Old messages compact when context limit reached
- Multiple sessions run concurrently without interference

**Architecture**: GenServer per session, ETS table for fast lookup, GenStage for persistence.

---

### Phase 5: Channel Adapter — Discord Bot

**Goal**: Receive Discord messages, route to agent, send responses back.

**Deliverables**:
- `Channels.Discord` adapter (Nostrum library)
- Message routing (Discord event → SessionServer)
- Response formatting (markdown → Discord embed)
- Typing indicator during processing
- Tests with mocked Discord events

**Success Criteria**:
- Discord message arrives → agent processes → response sent
- Typing indicator shows while thinking
- Multiple users can chat concurrently
- DM and channel messages both work

**Architecture**: Nostrum consumer process, routes to AgentSupervisor, streams back via Discord API.

---

### Phase 6: Tool Framework — Exec Tool

**Goal**: Define tool schema, execute tools, return results to provider.

**Deliverables**:
- Tool behavior + callback protocol
- `Tools.Exec` implementation (run shell commands)
- Tool result serialization (back to provider)
- Approval workflow (dangerous commands require confirm)
- Tests for tool execution lifecycle

**Success Criteria**:
- Agent calls exec tool → command runs → output returns
- Dangerous commands prompt for approval
- Tool errors don't crash agent
- Tool results integrate into conversation context

**Architecture**: Tool as callback module, executed in Task, tracked via Registry.

---

### Phase 7: Multi-Tenancy — Isolated Supervision Trees

**Goal**: Support multiple tenants (users/orgs), each with isolated agent supervision.

**Deliverables**:
- Tenant registry (lookup tenant by ID)
- Per-tenant supervisor (isolates agent crashes)
- Tenant config loading (separate YAML per tenant)
- Resource limits (max agents/sessions per tenant)
- Tests for tenant isolation

**Success Criteria**:
- Tenant A's agent crash doesn't affect Tenant B
- Each tenant loads independent config
- Resource limits enforced per tenant
- Can list all tenants and their running agents

**Architecture**: PartitionSupervisor or DynamicSupervisor per tenant, Registry for lookup.

---

### Phase 8: Observability — Telemetry + LiveDashboard

**Goal**: Expose metrics, traces, and live introspection UI.

**Deliverables**:
- Telemetry events (agent start/stop, API calls, tool execution)
- Metrics aggregation (request counts, latency histograms)
- Phoenix LiveDashboard integration
- Distributed tracing (OpenTelemetry optional)
- Documentation for monitoring setup

**Success Criteria**:
- LiveDashboard shows running processes
- Metrics track API call volume and latency
- Telemetry events captured for debugging
- Can trace a single request end-to-end

**Architecture**: :telemetry events, TelemetryMetrics, Phoenix.LiveDashboard as web UI.

---

## Post-Phase 8: Future Work (Not in Initial Build)

- Additional channels (Telegram, Slack, iMessage)
- Browser automation tooling (CDP integration)
- Skills/plugin system (dynamic tool loading)
- Distributed deployment (multi-node clustering)
- Advanced cron (Quantum integration)
- Memory search (vector DB integration)

---

## Development Workflow Per Phase

1. **SPEC** - Define acceptance criteria, architecture decisions
2. **RESEARCH** - Explore OpenClaw source, identify libraries/patterns
3. **PLAN** - Break down into concrete tasks
4. **BUILD** - Implement via CC Agent Teams
5. **REVIEW** - Code quality + adversarial test review via Codex
6. **REVISE** - Address critical/important findings (one round max)
7. **REFLECT** - Document learnings, surface issues for next phase
8. **COMMIT** - Git commit + push
9. **ESCALATE** - Report to main session, proceed to next phase

---

## Phase Dependency Graph

```
Phase 1 (Foundation)
   ↓
Phase 2 (Agent Lifecycle)
   ↓
Phase 3 (Provider) + Phase 4 (Session)  [parallel]
   ↓
Phase 5 (Channel)
   ↓
Phase 6 (Tools)
   ↓
Phase 7 (Multi-Tenancy)
   ↓
Phase 8 (Observability)
```

**Phases 3 and 4 can be built in parallel** - they don't depend on each other, both depend on Phase 2.

---

## Success Metrics (Overall Project)

- **Functional**: Agent receives Discord message → calls Anthropic → uses exec tool → responds
- **Resilient**: Agent crash → supervisor restarts → conversation continues
- **Observable**: LiveDashboard shows all running agents, sessions, API metrics
- **Multi-tenant**: Two tenants run concurrently without interference
- **Testable**: >80% test coverage, acceptance tests for each phase

---

**This plan is a living document.** REFLECTIONS.md from each phase may trigger adjustments to future phases. The goal is working software, not rigid adherence to a plan written before we learned anything.

---

## Notes

- OpenClaw source: `~/wrk/opc/openclaw/` (~311K lines, ~1700 files)
- BeamClaw2 project: `~/wrk/beamclaw2/`
- Reference BRIEF.md for project goals and non-goals
- Each phase should compile, test, and run independently
- Prefer small, incremental commits over big-bang releases
