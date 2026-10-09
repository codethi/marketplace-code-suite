---
name: debug
description: code-suite `debug` capability. Use when something is broken or behaving unexpectedly — an error, a failing or flaky test, a regression, wrong output — to reproduce it, find the root cause from evidence, and only then fix it. Used by the orchestrator's bug and investigation routes; also usable directly.
argument-hint: "[symptom or failing command]"
---

# Debug

Find the cause from evidence before changing code. Guess-and-patch fixes hide bugs and
create new ones.

The symptom: `$ARGUMENTS` (if empty, use the conversation so far).

## 1. Reproduce

Get a reliable way to see the failure: a failing test, a command, a request, a script.
Write down the exact steps and the actual vs. expected result.

- Read the whole error: message, stack trace, and the first frame in project code.
- If it is intermittent, run it repeatedly and record the failure rate.
- If you cannot reproduce it, stop. Report what you tried and what information would
  help (logs, inputs, environment). Do not ship a speculative fix.

Shrink the reproduction where cheap: smaller input, single test, fewer services.

## 2. Gather evidence

- Read the code on the failing path end to end (use the `explore` capability for
  unfamiliar areas).
- Check what changed: `git log` / `git diff` on the involved files; `git bisect` when
  there is a known good version.
- Check the environment: versions, config, env vars, data state.

## 3. Hypothesize and test

List the plausible causes, most likely first. For each, define a check that would
confirm or rule it out, and run it: a targeted log line, a debugger breakpoint, an
assertion, a minimal script, a reverted change. Change one thing at a time. Keep a short
log of hypotheses ruled out — it goes in the report.

## 4. Confirm the root cause

You have the root cause when you can explain the full chain from trigger to symptom and
predict a result you have not observed yet (and the prediction holds). "This line looks
wrong" is not yet a root cause.

If the root cause is in code you don't own (a dependency, another service), say so and
propose the local mitigation separately from the real fix.

## 5. Fix

In investigation mode (the user asked to find, not fix), stop here and report.

Otherwise:

1. Write the regression test first with the `test` capability; confirm it fails.
2. Fix the cause with the smallest change. Check for the same bug pattern elsewhere
   (grep for it) and mention other occurrences.
3. Confirm the regression test passes and the surrounding suite is green.
4. Remove temporary logs, breakpoints and scratch scripts.

If three fix attempts fail, stop patching. Return to step 3 with what the failures
taught you, and tell the user where things stand.

## 6. Report

- **Symptom** and how to reproduce it.
- **Root cause**, in one or two sentences, with `path:line`.
- **Fix** and the regression test that guards it.
- **Ruled out** — hypotheses eliminated, briefly.
- Other occurrences or follow-ups.
