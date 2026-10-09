---
name: test
description: code-suite `test` capability. Use when writing tests — a regression test for a bug, tests for new behavior, or characterization tests before a refactor — in the project's own framework and style, and proving each test can actually fail. Used by the orchestrator's bug, feature and refactor routes; also usable directly.
argument-hint: "[what to test]"
---

# Test

Write tests that would catch the problem they are meant to catch, in the style the
project already uses.

The target: `$ARGUMENTS` (if empty, use the conversation so far).

Rules for the whole skill:

- **Tests only, unless you are also the implementer.** When testing someone else's
  change (as the `tester` agent or after `implement`), edit only test files and
  fixtures. A failing test that exposes wrong behavior is a **bug found**: report it
  (section 7); never fix production code silently to make the test pass.
- **Fictitious credentials.** Passwords, tokens and keys in tests are obviously fake
  (`test-password-123`, `fake-token`), never real or realistic-looking secrets.
- **Never commit or push.** Delivery is someone else's step.

## 1. Pick the mode

| Mode | When | The test must |
| --- | --- | --- |
| **Regression** | Fixing a bug | Fail before the fix, pass after |
| **Behavior** | New feature | Cover each spec behavior and edge case |
| **Characterization** | Before a refactor | Pin current behavior, even if it looks odd |

## 2. Match the project

Before writing anything, find:

- The framework, runner and assertion style (from config and existing tests).
- Where tests live and how they are named (co-located, `test/`, `__tests__/`, `*_test.go`, ...).
- The nearest existing test for similar code. Imitate its structure, fixtures, factories
  and mocking approach.
- The command to run a single test file or test name.

Do not introduce a new test library, mocking library or helper pattern when the project
already has one.

## 3. Map the acceptance criteria

For behavior tests, list the acceptance criteria (CA) from the spec, plan task or
brief, then plan the tests before writing them. Each CA gets at least one test, and
together they cover:

- **Happy path** — the CA's main behavior.
- **Errors from the spec** — each error case the spec names, with the expected
  response or exception.
- **Boundaries** — limits, empty and maximum values, the first invalid value.
- **What must NOT happen** — side effects that must be absent: no write on failure, no
  access to another user's resource, no secret in logs or responses, no duplicate on
  retry.

A CA you cannot test (needs a real external service, manual check) is listed as not
covered, with the reason. Do not drop it silently.

## 4. Write good tests

- Test behavior through the public interface, not private internals.
- One reason to fail per test; the name states the behavior
  (`returns 404 when product does not exist`).
- Arrange / act / assert, with the arrange step as small as possible.
- Deterministic: no real network, clock, randomness or ordering dependence unless the
  project's integration tests do that on purpose. No sleeps; wait on conditions.
- Mock at system boundaries (HTTP, queues, third-party SDKs), following project
  convention for databases.
- Edge cases: empty, missing, boundary values, invalid input, duplicates, permissions,
  concurrency where relevant.

## 5. Prove the test

A test that never failed proves nothing.

- **Regression:** run it before applying the fix and confirm it fails for the expected
  reason (the assertion, not a setup error). If the fix is already applied, temporarily
  revert it, confirm the failure, and restore the fix.
- **Behavior:** confirm at least one assertion fails if the key line of the
  implementation is broken (briefly mutate it, then restore).
- **Characterization:** confirm the tests pass against the unchanged code before the
  refactor begins.

These temporary reverts and mutations are the only allowed touches to production code
when you are testing someone else's change. Restore them right away and confirm with
`git diff -- <production paths>` that nothing remains.

## 6. Run the whole suite

Run the new tests, then the **entire** test suite, not just the touched file. Read the
output. A failure you did not cause (pre-existing, environmental) is reported as such,
not fixed.

## 7. Bug found

When a correct test fails because the production code is wrong:

- Keep the test failing. Do not skip it, loosen the assertion or change the expected
  value to match the bug.
- Do not fix the production code yourself unless you are also the task's implementer and
  the fix is inside its scope; otherwise report it.
- Report it as **bug encontrado** with evidence: the test (`path:line`), the command,
  the expected vs. actual result, and the relevant 5–20 lines of output.

## 8. Report

```markdown
**Status:** <pass | bug encontrado | partial> — <one sentence>
**Suite:** `<command>` → <passed/failed/skipped counts>

| CA | Tests | Covers |
| --- | --- | --- |
| CA1 <short text> | `path:line` <test name> | happy path, error X, boundary, must-not |
| CA2 ... | — | not covered: <reason> |

**Bugs encontrados:**
- <test `path:line`> — expected <x>, got <y>; `<command>`; <output excerpt>

**Notes:** <behaviors deliberately not tested and why; pre-existing failures>
```
