---
name: plan
description: code-suite `plan` capability. Use before a multi-step code change to break it into ordered, independently verifiable tasks with files, dependencies and an execution strategy (inline or parallel subagents). Used by the orchestrator's feature and refactor routes; also usable directly.
argument-hint: "[change to plan]"
---

# Plan

Turn an agreed goal (a request or a confirmed spec) into tasks that can be executed and
verified one at a time.

The change: `$ARGUMENTS` (if empty, use the conversation so far, including any spec).

## 1. Inputs

You need a map of the code involved. If you do not have one, get it with the `explore`
capability (`code-suite:code-explorer` when available) before planning. Plans built on
guessed file paths fail at the first task.

## 2. Cut tasks

Each task:

- Has one goal and leaves the build and tests green when done.
- Is small enough to review as one diff (roughly one commit).
- Includes its own tests; testing is not a separate final task.
- Names the files it creates or changes.

Order tasks so contracts come before their consumers: types/schemas/interfaces →
core logic → wiring (routes, DI, config) → UI/CLI surface → docs. For refactors, every
step must preserve behavior and keep the safety-net tests passing.

## 3. Write the plan

```markdown
# Plan: <name>

**Approach** — <2–4 sentences: the shape of the solution and why this one>

| # | Task | Files | Depends on | Verify |
| --- | --- | --- | --- | --- |
| 1 | <goal> | `path`, `path` | — | `<command>` / <test name> |
| 2 | ... | ... | 1 | ... |

**Execution** — <inline, or which tasks go to parallel subagents>
**Risks** — <what could go wrong and how you'll notice; rollback if relevant>
```

## 4. Choose the execution strategy

- **Inline** — default for tasks that are sequential or touch the same files.
- **Parallel subagents** — only for tasks with no dependency between them **and**
  disjoint file sets. Dispatch each to the `implement` capability
  (`code-suite:implementer` when available) in the same turn.
- Never let two concurrent workers edit the same file.

## 5. Gate and track

- For size L changes, or whenever the user asked to review the plan, present it and
  wait for approval before editing anything.
- Once approved, mirror the tasks in the session's task list if one is available and
  update it as tasks complete.
- If execution reveals the plan is wrong (a missing dependency, a file that doesn't
  exist, a larger blast radius), stop, revise the affected tasks, and tell the user
  what changed before continuing.
