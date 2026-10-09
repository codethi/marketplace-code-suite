---
name: spec
description: code-suite `spec` capability. Use before building a large feature or whenever requirements are unclear, to turn a request into a short, testable specification (behavior, contract, edge cases, out of scope, acceptance criteria) agreed with the user. Used by the orchestrator's feature route; also usable directly.
argument-hint: "[feature or change to specify]"
---

# Spec

Turn a request into a specification the user agrees with and an implementer can verify.
A spec is a tool for catching wrong assumptions before code exists, not a document for
its own sake: keep it as short as the change allows.

The request: `$ARGUMENTS` (if empty, use the conversation so far).

## 1. Learn before asking

Understand the current system first, so you only ask what the code cannot answer.
If the area is unfamiliar, use the `explore` capability (`code-suite:code-explorer`
when available). Note the existing behavior the change touches and the closest similar
feature, whose shape the new one should probably follow.

## 2. Separate decisions from details

List what is unknown, then sort each item:

- **Inferable** — answerable from the code, conventions or common sense. Decide it and
  record the choice in the spec as an assumption.
- **The user's decision** — product behavior, scope, trade-offs with real cost
  (compatibility, data migration, UX). Ask.

Ask all of the user's decisions in one batch, at most ~4 questions, each with concrete
options and your recommendation first. Use a structured question tool if the session
has one.

## 3. Write the spec

Present it in chat using this template, omitting sections that do not apply:

```markdown
# Spec: <name>

**Goal** — <one sentence: who gets what>

**Behavior**
- Given <state>, when <action>, then <observable result>
- ...

**Contract** — <API shapes, signatures, CLI flags, events, schema changes>

**Edge cases & errors**
- <input/state> → <expected result>

**Constraints** — <performance, security, compatibility, only if relevant>

**Out of scope** — <what this change will not do>

**Assumptions** — <inferable decisions you made>

**Acceptance criteria**
- [ ] <checkable statement, ideally mapping to a test>
```

Every behavior and edge case should be checkable by a test or a command. Rewrite vague
words ("fast", "robust", "user-friendly") as something measurable or drop them.

## 4. Confirm

Ask the user to confirm or correct the spec. Do not start planning or implementing until
they confirm. Incorporate corrections and show only what changed.

The confirmed spec is the reference for `plan`, `test` and `review`.
