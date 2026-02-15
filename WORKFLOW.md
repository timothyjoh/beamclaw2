# WORKFLOW.md — Phase Lifecycle Configuration

Copy this file to your project root and customize. The Supervisor reads this to execute your build process.

## Workflow Steps

Each step has: a prompt template, which agent runs it, and where artifacts go.

```yaml
workflow:
  name: "Project Build Workflow"
  version: 1
  
  # Where phase artifacts live (relative to project root)
  phases_dir: "docs/phases"
  
  # Project-level docs
  project_overview: "PLAN.md"  # or README.md, docs/architecture.md, etc.

  # Pre-flight checks — run before starting ANY project
  preflight:
    - name: "Update tools"
      commands:
        - "npm update -g @openai/codex"
        - "brew upgrade claude-code || true"
        - "brew upgrade gemini-cli || true"
    - name: "Auth smoke test"
      commands:
        - "codex --full-auto 'echo hello world' # verify codex auth works"
        - "claude --dangerously-skip-permissions --version # verify claude code works"
      on_fail: "Stop and fix auth before proceeding"
      note: "Codex uses --full-auto (yolo mode). Claude Code uses --dangerously-skip-permissions."
    - name: "Capture baseline usage"
      command: "# Run /usage in CC and log to docs/phases/usage.jsonl"

  steps:
    - name: spec
      description: "Break overall concept into phase spec"
      prompt: "prompts/spec.md"  # From cc-agent-teams skill, or project-local override
      agent: "cc-opus"           # Claude Code with Opus
      output: "SPEC.md"
      escalate: true             # Surface to Rita + Butter before continuing
      blocking: false            # Don't wait for approval — inform only

    - name: research
      description: "Fresh codebase analysis for this phase"
      prompt: "prompts/research.md"
      agent: "cc-opus"
      output: "RESEARCH.md"
      inputs: ["SPEC.md"]
      escalate: false

    - name: plan
      description: "Concrete task list from spec + research"
      prompt: "prompts/plan.md"
      agent: "cc-opus"
      output: "PLAN.md"
      inputs: ["SPEC.md", "RESEARCH.md"]
      escalate: true             # Surface the plan to Rita + Butter
      blocking: false

    - name: build
      description: "Coordinator + team implements the plan"
      prompt: null               # Supervisor constructs from PLAN.md tasks
      agent: "cc-agent-team"     # Claude Code with Agent Teams enabled
      output: "CHANGES.md"       # Generated from git diff after build
      inputs: ["SPEC.md", "RESEARCH.md", "PLAN.md"]
      team_size: 3               # Default team size
      require_tests: true        # Unit + e2e tests must be part of build

    - name: review
      description: "Code quality + adversarial test review"
      prompt: "prompts/review.md"
      agent: "codex-cli"         # Swappable — could be cc-opus, gemini, etc.
      output: "REVIEW.md"
      inputs: ["SPEC.md", "PLAN.md", "RESEARCH.md"]
      sub_reviewers:
        - role: "code-quality"
          focus: "spec compliance, code quality, error handling, architecture"
        - role: "adversarial-tester"
          focus: "mock abuse, happy-path-only, boundary conditions, assertion quality"

    - name: revise
      description: "Address review findings"
      prompt: null               # Supervisor constructs from REVIEW.md
      agent: "cc-agent-team"
      inputs: ["REVIEW.md", "PLAN.md"]
      max_rounds: 1              # One revision round, then move on
      require_build_pass: true   # Code must compile + tests pass
      require_tests_pass: true

    - name: reflect
      description: "Look back + look forward"
      prompt: "prompts/reflect.md"
      agent: "cc-opus"
      output: "REFLECTIONS.md"
      inputs: ["SPEC.md", "PLAN.md", "RESEARCH.md", "REVIEW.md", "CHANGES.md"]
      escalate: true             # Surface reflection to Rita + Butter

    - name: commit
      description: "Git commit + push"
      agent: "supervisor"        # Supervisor handles directly
      command: "cd {{PROJECT_DIR}} && git add -A && git commit -m 'Phase {{PHASE_NUMBER}}: {{PHASE_NAME}}' && git push"

  # Usage tracking — capture CC /usage at phase boundaries
  usage_log: "docs/phases/usage.jsonl"
  # Format: {"timestamp":"ISO","phase":"name","event":"start|end","usage_session":"X%","usage_weekly":"Y%"}
  # Supervisor captures /usage in CC at start and end of each phase

  # What carries forward between phases
  carry_forward:
    - "REFLECTIONS.md"           # Previous phase's reflections → next phase's spec writer
    
  # Escalation settings
  escalation:
    on_error: true               # Always escalate build/test failures
    on_question: true            # Escalate when agents hit decision points
    on_stuck: true               # Escalate after 3+ retries on same error
    max_retries_before_escalate: 3
```

## Customization

### Swap the reviewer agent
Change `steps.review.agent` from `codex-cli` to any supported agent:
- `codex-cli` — OpenAI Codex CLI (default)
- `cc-opus` — Claude Code with Opus
- `cc-sonnet` — Claude Code with Sonnet
- `gemini` — Gemini CLI

### Adjust team size
Change `steps.build.team_size` to control how many CC teammates spawn.

### Make a step blocking
Set `blocking: true` on any step to require explicit approval before continuing.
By default, `escalate: true` + `blocking: false` means "inform, don't wait."

### Add/remove steps
The Supervisor follows steps in order. Add, remove, or reorder as needed.

### Override prompts per project
Copy a prompt from the skill's `prompts/` dir to your project and update the path:
```yaml
- name: research
  prompt: "docs/prompts/my-custom-research.md"  # Project-local override
```
