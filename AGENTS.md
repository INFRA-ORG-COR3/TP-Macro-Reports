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
