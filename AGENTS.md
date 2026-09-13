<!-- AI-CONTEXT-STANDARD:BEGIN -->
## Persistent Context Bootstrap

This repository uses the Universal AI Project Context Standard.

Before context-dependent technical work:
1. Read `CONTEXT_INDEX.md`.
2. Read `PROJECT_PROFILE.md`.
3. Read `PROJECT_STATE.md`.
4. Read `tasks/ACTIVE_TASK.md`.
5. Read the referenced active task.
6. Load only task-relevant modules.

Repository/project evidence is authoritative over stale conversation history.
Do not read every Markdown file by default.
Do not repeat a documented failed approach without new evidence.
Respect task scope and stop conditions.
<!-- AI-CONTEXT-STANDARD:END -->

# AGENTS.md

## Purpose

This project uses persistent, low-token project context. Repository/project files are authoritative when they conflict with assumptions or stale conversation context.

## Mandatory Startup

Before context-dependent technical recommendations or modifications:

1. Read `CONTEXT_INDEX.md`.
2. Read `PROJECT_PROFILE.md`.
3. Read `PROJECT_STATE.md`.
4. Read `tasks/ACTIVE_TASK.md`.
5. If an active task exists, read the referenced `TASK-xxx.md`.
6. Inspect the relevant baseline/evidence.
7. Load only the additional modules routed by `CONTEXT_INDEX.md` or required by the task.

Do **not** read every documentation file by default.

## Context Routing

- Architecture/topology/flows -> `ARCHITECTURE.md`
- Requirements/acceptance -> `REQUIREMENTS.md`
- Important decisions/rationale -> `DECISIONS.md`
- Known recurring failures -> `KNOWN_FAILURES.md`
- Validated reusable fixes -> `KNOWN_FIXES.md`
- Hosts/environments/versions -> `ENVIRONMENT.md`
- Security/data boundaries -> `SECURITY.md`
- Validation/test strategy -> `TESTING.md`
- Deployment/release -> `DEPLOYMENT.md`
- Operations/recovery -> `RUNBOOK.md`
- External systems/APIs -> `INTEGRATIONS.md`
- Data/schema/business rules -> `DATA_MODEL.md`
- Data quality/grain/freshness -> `DATA_PROFILE.md`
- Long-document/source navigation -> `SOURCE_INDEX.md`
- Risks/mitigations -> `RISKS.md`
- Future candidate work -> `BACKLOG.md`
- Terms/aliases -> `GLOSSARY.md`

## Default Working Method

`verify baseline -> preserve/backup -> diagnose -> surgical change -> diff -> build/test/validate -> update context -> commit`

## Critical Rules

- Never discard uncommitted work without preserving it first.
- Verify the current repository/project before Git operations.
- Separate diagnosis from modification.
- Do not deploy or modify UAT/production unless explicitly authorized by the active task/user.
- Never expose or commit passwords, tokens, API keys, private keys, MFA secrets, recovery codes, or connection strings.
- Do not repeat a documented failed approach unless new evidence materially changes applicability.
- Do not assume commands, tools, modules, APIs, features, versions, permissions, or network paths exist; verify when material.
- Prefer evidence over speculation.
- Never promote `ASSUMED` to `CONFIRMED` without evidence.
- Minimize unrelated changes.
- Respect task scope, acceptance criteria, and stop condition.
- After two materially similar failed attempts, stop guessing and collect new evidence before continuing.

## Failure Knowledge

Before recurring troubleshooting:

1. Search `KNOWN_FAILURES.md`.
2. Search `KNOWN_FIXES.md`.
3. Verify applicability of any existing fix.
4. Avoid any `Do Not Retry` method unless conditions changed.

Update `KNOWN_FAILURES.md` only for confirmed, reusable failures likely to recur.

Update `KNOWN_FIXES.md` only after the solution is validated. Untested fixes stay in the active task as hypotheses.

## Context Maintenance

- Current state changed -> update `PROJECT_STATE.md`.
- Architecture changed -> update `ARCHITECTURE.md`.
- Requirement changed -> update `REQUIREMENTS.md`.
- Important decision made/superseded -> update `DECISIONS.md`.
- Reusable failure learned -> update `KNOWN_FAILURES.md`.
- Reusable fix validated -> update `KNOWN_FIXES.md`.
- Risk changed -> update `RISKS.md`.
- Task completed -> move it to `tasks/completed/`.
- Next task clearly defined -> create it and update `tasks/ACTIVE_TASK.md`.
- Active task/context changed -> update `CONTEXT_INDEX.md`.

## Definition of Done

A task is complete only when:

- requested scope is complete;
- validation was executed or a documented reason explains why it could not be;
- relevant diff/change evidence was reviewed;
- no unrelated changes remain;
- material context files reflect the new truth;
- task state is updated;
- explicit stop conditions were respected.

<!-- BEGIN MANAGED BLOCK: AI-OPERATING-STANDARD-VNEXT -->

## AI Execution and Validation Standard

### Source of Truth

Repository context is authoritative.

Read in this order when applicable:

1. `AGENTS.md`
2. `PROJECT_STATE.md`
3. current `tasks/active/TASK-xxx.md`
4. `VALIDATION_STATE.md`
5. `DECISIONS.md`
6. `KNOWN_FAILURES.md`
7. `KNOWN_FIXES.md`

Do not depend on conversation history when repository context provides the answer.

### Task Isolation

Default operating rule:

`1 objective = 1 task = 1 thread = 1 TASK-xxx.md = 1 validation contract`

Do not expand the implementation scope merely because an adjacent issue is discovered.

Record unrelated work as a separate task.

### Required Implementation Flow

Use this sequence:

`context -> baseline -> risk -> validation contract -> change -> diff -> minimum justified validation -> context update -> commit`

Before modification:

1. Read repository context.
2. Confirm repository and branch.
3. Preserve existing uncommitted work.
4. Establish the baseline.
5. Assign validation risk V0-V3.
6. Define the task Validation Contract.

After modification:

1. Review the actual diff.
2. Identify which previous validation evidence the diff invalidates.
3. Run only validation justified by the diff and risk.
4. Update `VALIDATION_STATE.md`.
5. Update task and project context.
6. Record decisions, failures, and fixes when applicable.
7. Review the final diff.
8. Commit only after required validation succeeds.

### Validation Risk Levels

#### V0 - Documentation / comments / metadata / formatting

Required:

- diff review

Optional only when relevant:

- parser check
- formatting check
- syntax validation

Do not run builds or test suites when executable behavior cannot be affected.

#### V1 - Small isolated implementation or configuration change

Required:

- diff review
- directly affected syntax, lint, parser, or targeted test

Do not run the complete repository test suite by default.

#### V2 - Cross-file / dependency / interface change

Required:

- diff review
- targeted tests
- build or typecheck when applicable

Broader validation requires a dependency or blast-radius justification.

#### V3 - Production / infrastructure / authentication / security / database / networking

Required as applicable:

- baseline
- backup or rollback path
- diff review
- targeted validation
- relevant build
- relevant integration or smoke test
- rollback or recovery verification

V3 does not mean "run everything."

Validation must still correspond to the actual affected surface.

### No Redundant Validation

Before running a validation command, determine whether the current diff can invalidate the previous successful result.

If the current diff cannot affect what a previous validation demonstrated, that validation remains valid.

Do not rerun unaffected broad test suites simply because a later small change occurred.

Revalidate only:

- changed behavior
- changed dependencies
- changed interfaces
- changed configuration
- changed security boundaries
- changed infrastructure surfaces

If validation beyond the active Validation Contract is proposed, identify the new risk that justifies it before running it.

### Validation Contract

Every implementation task must define before modification:

- risk level
- expected files or systems
- required validation
- validation explicitly not required
- escalation conditions

The Validation Contract is the default validation ceiling unless the implementation exposes a new risk or dependency.

### Model and Reasoning Routing

Use the least expensive reasoning level that can reliably complete the task.

Routine work:

- documentation
- known fixes
- narrow scripts
- straightforward implementation
- isolated configuration changes

Default to balanced or medium reasoning.

Complex work:

- unclear root cause
- cross-file refactor
- architecture
- unfamiliar codebase
- difficult networking or infrastructure diagnosis

Use high reasoning.

Exceptional work:

- security-sensitive investigation
- difficult production incident
- major migration
- highly ambiguous multi-system problem
- repeated previous failures

Use the highest-capability model available when justified.

Do not escalate reasoning because a task is long.

Escalate because uncertainty, dependency depth, blast radius, or risk is high.

### Execution Surface Routing

Use Chat for:

- decisions
- architecture discussion
- diagnosis
- prompt design
- quick analysis

Use Codex for:

- repository implementation
- coding
- PowerShell development
- refactoring
- Git
- tests
- code review

Use Work for:

- long multi-step investigations
- multi-file research
- cross-application work
- web plus file workflows
- finished professional deliverables

Git remains the technical source of truth regardless of execution surface.

### Change Discipline

Do not:

- make speculative changes
- deploy merely to validate local reasoning
- discard uncommitted work
- assume an optional tool is installed
- assume repository location
- mark previous validation stale without a relevant diff
- expand task scope without recording the expansion

Prefer:

`baseline -> backup -> surgical change -> diff -> minimum justified validation -> context update -> commit`

<!-- END MANAGED BLOCK: AI-OPERATING-STANDARD-VNEXT -->
