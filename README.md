# code-suite

A stack-agnostic engineering suite for [Claude Code](https://claude.com/claude-code),
distributed as a plugin marketplace. At its center is an **orchestrator** skill that
classifies each request, sizes it, and routes it through the right workflow, delegating
to specialized skills, subagents and hooks as the suite grows.

## Install

```text
/plugin marketplace add codethi/marketplace-code-suite
/plugin install code-suite@code-suite
```

Restart Claude Code after installing.

## Usage

**Run the whole flow in one go** with `/code`:

```text
/code add pagination to the products endpoint
/code fix the flaky checkout test --commit
/code add rate limiting to the gateway --pr
```

It grounds itself in the repo, asks any real decisions **once, up front**, then runs
spec → plan → implement → test → verify → review → deliver without stopping between
phases. Verification and review failures are fixed in a loop (up to three cycles).
By default nothing is committed; `--commit` commits, `--pr` also pushes a branch and
opens a pull request. It still stops if the task rests on a wrong premise, needs
clearly more scope than asked, or would do something destructive.

**Step by step, with approval gates**, use the orchestrator:

```text
/code-suite:orchestrator add pagination to the products endpoint
```

or just describe the task; Claude loads the orchestrator for software engineering
requests. On large changes it stops for you to approve the plan before editing.

If another plugin also defines `/code`, use the namespaced form `/code-suite:code`.

## How the orchestrator works

1. **Ground** — reads project instructions, detects the stack and the test/lint/build commands.
2. **Classify** — `question`, `bug`, `feature`, `refactor`, `review`, `chore` or `investigation`.
3. **Size** — S, M or L. Size decides ceremony; L requires your approval of a plan before any edit.
4. **Route** — runs the type's playbook ([routes.md](plugins/code-suite/skills/orchestrator/references/routes.md)).
5. **Delegate** — each step goes to a skill, then a subagent, then inline work, following the
   [capability registry](plugins/code-suite/skills/orchestrator/references/capabilities.md).
6. **Verify and report** — runs the project's real checks and reports results honestly.

It always stops for your confirmation before pushing, opening PRs, deleting data or running
non-local migrations.

## Components

Each workflow step is a **capability**. The orchestrator resolves it to a skill (runs in
the main conversation) or a subagent (runs isolated, can run in parallel), and does the
step itself when neither is installed.

| Capability | Component | Type | What it does |
| --- | --- | --- | --- |
| — | `orchestrator` | skill | Classifies, sizes and routes every request |
| — | `code` | skill (`/code`) | Runs the full flow end to end in one go |
| `explore` | `code-explorer` | subagent | Read-only map of entry points, flow, conventions and tests |
| `spec` | `spec` | skill | Turns a request into a short, testable spec agreed with you |
| `plan` | `plan` | skill | Ordered, verifiable tasks and an execution strategy |
| `implement` | `implementer` | subagent | Executes one scoped task with its tests; parallel when files are disjoint |
| `test` | `test` | skill | Regression, behavior and characterization tests that are proven to fail |
| `debug` | `debug` | skill | Reproduce → evidence → root cause → fix |
| `review` | `code-reviewer` | subagent | Independent review; only findings with a concrete failure scenario |
| `verify` | `verifier` | subagent | Runs tests, lint, type-check and build; honest pass/fail report |
| `deliver` | `deliver` | skill | Clean diff and summary; commit / PR only when you ask |

Every skill can also be invoked directly, e.g. `/code-suite:debug the checkout test is flaky`.

Hooks are planned.

## Repository layout

```text
.claude-plugin/marketplace.json      # marketplace manifest
plugins/code-suite/
  .claude-plugin/plugin.json         # plugin manifest
  agents/                            # subagents: code-explorer, implementer, code-reviewer, verifier
  skills/
    orchestrator/
      SKILL.md
      references/routes.md           # per-type playbooks
      references/capabilities.md     # capability → component registry
    code/                            # /code: full flow in one run
    spec/ plan/ test/ debug/ deliver/
```

## Local development

```bash
claude plugin validate .
claude plugin validate plugins/code-suite
```

To try local changes, add the clone as a marketplace: `/plugin marketplace add ./path/to/clone`.

## License

[MIT](LICENSE)
