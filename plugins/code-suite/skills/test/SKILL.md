---
name: test
description: code-suite `test` capability. Use when writing tests — a regression test for a bug, tests for new behavior, or characterization tests before a refactor — in the project's own framework and style, and proving each test can actually fail. Used by the orchestrator's bug, feature and refactor routes; also usable directly.
argument-hint: "[what to test]"
---

# Test

Write tests that would catch the problem they are meant to catch, in the style the
project already uses.

The target: `$ARGUMENTS` (if empty, use the conversation so far).

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

## 3. Write good tests

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

## 4. Prove the test

A test that never failed proves nothing.

- **Regression:** run it before applying the fix and confirm it fails for the expected
  reason (the assertion, not a setup error). If the fix is already applied, temporarily
  revert it, confirm the failure, and restore the fix.
- **Behavior:** confirm at least one assertion fails if the key line of the
  implementation is broken (briefly mutate it, then restore).
- **Characterization:** confirm the tests pass against the unchanged code before the
  refactor begins.

## 5. Run and report

Run the new tests and then the surrounding test file or suite. Report which tests were
added, what each protects, and the run result. Mention behaviors you chose not to test
and why.
