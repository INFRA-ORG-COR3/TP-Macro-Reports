<!-- BEGIN MANAGED BLOCK: TASK-TEMPLATE-VNEXT -->

# TASK-XXX - Task Title

## Objective

Define one implementation objective.

## Scope

### In Scope

- Define the intended work.

### Out of Scope

- Define adjacent work that must not be included.

## Baseline

Repository:

Branch:

Starting commit:

Relevant current behavior:

## Validation Contract

Risk: `V0 | V1 | V2 | V3`

### Expected Changes

- List expected files, interfaces, systems, or configuration surfaces.

### Required Validation

- Diff review
- Add only validation justified by risk and affected surface.

### Not Required

Explicitly identify broad validation that is unnecessary for this task.

Examples:

- full repository test suite
- deployment
- integration testing
- unrelated infrastructure validation

### Escalation Conditions

Broader validation is justified only when implementation introduces:

- a new dependency
- an interface change
- a security boundary change
- a larger blast radius
- modification outside expected scope

## Implementation Notes

Record only information required to resume the task.

## Validation Results

For each validation record:

- validation performed
- affected scope
- result
- whether evidence remains valid

## Completion Criteria

- Objective implemented.
- Final diff reviewed.
- Validation Contract satisfied.
- `VALIDATION_STATE.md` updated.
- `PROJECT_STATE.md` updated when project state changed.
- Relevant decisions recorded.
- Relevant known failures/fixes recorded.
- Task moved to `tasks/completed/`.
- Commit created.

<!-- END MANAGED BLOCK: TASK-TEMPLATE-VNEXT -->
