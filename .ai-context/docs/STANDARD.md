# Universal AI Project Context Standard v1.0

## Objective

Provide a universal, durable, low-token context system for AI-assisted technical and analytical work.

The project — not the chat transcript — should retain enough structured truth for a new AI session to resume safely and efficiently.

## Supported Work

- Software / coding
- Network / FortiGate / Wi-Fi
- Servers / infrastructure
- SaaS / Freshservice / business platforms
- Excel / CSV / data analysis
- Policies / documents / research
- Mixed/universal projects

## Core Files

| File | Question it answers | Routine read? |
|---|---|---|
| `AGENTS.md` | How must the AI work? | Always |
| `CONTEXT_INDEX.md` | What should be read now? | Always |
| `PROJECT_PROFILE.md` | Which modules apply? | Always |
| `PROJECT_STATE.md` | Where are we now? | Always |
| `tasks/ACTIVE_TASK.md` | What task is active? | Always |
| `TASK-xxx.md` | What exactly are we doing? | When active |
| `ARCHITECTURE.md` | How is it built/connected? | Relevant only |
| `REQUIREMENTS.md` | What must be true? | Relevant only |
| `DECISIONS.md` | Why was a material choice made? | Relevant only |
| `KNOWN_FAILURES.md` | What known failure must not recur? | Troubleshooting |
| `KNOWN_FIXES.md` | What validated remediation can be reused? | Troubleshooting |
| `SECURITY.md` | What boundaries/controls apply? | Security/data/infra |
| `ENVIRONMENT.md` | Where/what versions are running? | Environment work |
| `TESTING.md` | How do we prove the change? | Validation work |
| `DEPLOYMENT.md` | How is approved change released? | Deployment only |
| `RUNBOOK.md` | How is it operated/recovered? | Operations |
| `INTEGRATIONS.md` | How do external systems interact? | Integration work |
| `DATA_MODEL.md` | What is the data structure/rule set? | Data work |
| `DATA_PROFILE.md` | Is the dataset trustworthy/current? | Data analysis |
| `SOURCE_INDEX.md` | Where is evidence in long docs/files? | Document work |
| `RISKS.md` | What can go wrong and how is it mitigated? | Relevant only |
| `BACKLOG.md` | What future work exists but is not authorized? | Planning only |
| `GLOSSARY.md` | What terminology could be ambiguous? | On demand |

## Fact States

Use these labels when epistemic status matters:

- `CONFIRMED` — supported by evidence.
- `ASSUMED` — working assumption, not yet verified.
- `PENDING` — expected input/action/evidence not yet available.
- `BLOCKED` — cannot proceed because a dependency is unresolved.
- `DEPRECATED` — previously valid but no longer authoritative.

Never silently convert `ASSUMED` into `CONFIRMED`.

## Source-of-Truth Precedence

When information conflicts, prefer:

1. current verified system/data evidence;
2. current project configuration/code/data;
3. current authoritative context Markdown;
4. active task;
5. requirements/decisions;
6. completed tasks and Git history;
7. conversation memory;
8. assumptions.

## Token Efficiency

Prefer small routed reads over loading the whole repository.

Good:

- stable IDs;
- section references;
- `key: value`;
- current state instead of narrative history;
- task-specific evidence;
- Mermaid for topology;
- source indexes for long documents;
- data profiles for structured datasets.

Avoid:

- replaying chat transcripts;
- chronological diaries in `PROJECT_STATE.md`;
- duplicating the same fact in many files;
- reading every `.md` every turn;
- storing trivial transient errors as permanent knowledge.

## Failure / Fix Knowledge

`KNOWN_FAILURES.md` requires a confirmed reusable failure.

`KNOWN_FIXES.md` requires a validated reusable remediation.

Untested remediation stays in the active task as a hypothesis.

If two materially similar attempts fail, stop trying variants without new evidence. Reassess assumptions and collect new evidence first.

## Task Lifecycle

### Start

1. Confirm objective.
2. Verify/preserve baseline.
3. Create one scoped task.
4. Set `tasks/ACTIVE_TASK.md`.
5. Route `CONTEXT_INDEX.md` to relevant files/sections.

### Execute

`baseline -> preserve/backup -> diagnose -> surgical change -> diff -> fast validation -> targeted/full validation as justified`

### Close

1. Confirm acceptance criteria.
2. Update `PROJECT_STATE.md`.
3. Update architecture/requirements/decisions only if material truth changed.
4. Record reusable failures/fixes only when criteria are met.
5. Update risks if needed.
6. Move task to `tasks/completed/`.
7. Create next task only if scope is clearly defined.
8. Update `tasks/ACTIVE_TASK.md`.
9. Update `CONTEXT_INDEX.md`.
10. Review diff.
11. Commit when authorized/appropriate.

## Project Profiles

Profiles define enabled modules, not files that must be read on every task.

### Software

Architecture, requirements, decisions, failures/fixes, security, environment, testing, deployment, integrations, data model, risks, backlog, glossary.

### Network

Architecture/topology, requirements, decisions, failures/fixes, security, environment, testing, deployment/change method, runbook, integrations, risks, backlog, glossary.

### Server

Architecture, requirements, decisions, failures/fixes, security, environment, testing, deployment, runbook, integrations, risks, backlog, glossary.

### SaaS

Architecture/process, requirements, decisions, failures/fixes, security, environment, testing, runbook, integrations, data model, risks, backlog, glossary.

### Data

Requirements, decisions, failures/fixes, security, testing, data model, data profile, source index, risks, backlog, glossary.

### Policy

Requirements, decisions, security, testing/review criteria, source index, risks, backlog, glossary.

### Universal

All modules enabled, still read selectively.

## ChatGPT / Codex Bootstrap

When the AI has folder/repository access:

`Read AGENTS.md and resume the active task.`

A new thread should reconstruct the task from files rather than request a replay of previous chats.

When ChatGPT does not have access to local files, it must not claim it read them. Attach, expose, or retrieve the project files through an available project/workspace/file mechanism first.

## Mind Maps

Mind maps may be generated as a human navigation aid, but are not the authoritative project memory. Use structured Markdown and Mermaid for machine-readable relationships.

## Principle

> The AI should not have to remember the project. The project should remember itself.
