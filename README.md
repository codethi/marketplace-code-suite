# code-suite

## What it is

A stack-agnostic engineering suite for [Claude Code](https://claude.com/claude-code),
distributed as a plugin marketplace. An **orchestrator** classifies each request,
rates its size and risk, and routes it through the right workflow — spec, plan, ADRs,
implementation, tests, review, docs sync — delegating to specialized skills and
subagents. Deterministic helper scripts detect the repository context, keep an evidence
ledger per task and scan for secrets, and a hook blocks commits and pushes that contain
secrets. A task is only declared done when its evidence (tests, review, diff review,
secret scan) is recorded on the delivered commit.

## Install

```bash
claude plugin marketplace add codethi/marketplace-code-suite
claude plugin install code-suite@code-suite
```

Restart Claude Code after installing.

## Usage

**Run the whole flow** with `/code-suite:code` (or `/code` if no other plugin defines it):

```text
/code-suite:code add pagination to the products endpoint
/code-suite:code add rate limiting to the gateway --auto
/code-suite:code migrate sessions to Redis --ate-plano
/code-suite:code fix the flaky checkout test --auto --pr
```

| Flag | Effect |
| --- | --- |
| *(none)* | Runs the flow and stops at the orchestrator's approval gates (e.g. the plan of a large change). |
| `--auto` | Asks its questions once, up front, then runs to the end without approval stops. |
| `--ate-plano` | Runs up to the plan — goal, spec, plan and ADRs saved — and stops for your review. Nothing is implemented. |
| `--pr` | After the evidence gate passes, pushes the branch and opens a pull request. |

On code-changing tasks it works on a `feat/<slug>` branch and commits each task locally
(Conventional Commits). It never pushes or opens a PR without `--pr` or your
confirmation, and it stops on a dirty working tree, a project with no test command, an
unanswered high-risk question, or validation still failing after two correction rounds.

**Step by step**, use the orchestrator, or just describe the task — Claude loads it for
software engineering requests:

```text
/code-suite:orchestrator add pagination to the products endpoint
```

## How the orchestrator works

1. **Ground** — `cs-context` detects branch, stack and test/build/lint commands; reads project instructions.
2. **Classify, size, risk** — type (`question`, `bug`, `feature`, `refactor`, `review`,
   `chore`, `investigation`), size S/M/L, risk low/medium/high (the stricter one when in doubt).
3. **Start and intake** — branch `feat/<slug>`, evidence folder `.code-suite/<slug>/`,
   gaps rated by risk and asked once; answers go to `goal.md`.
4. **Route** — the type's playbook ([routes.md](plugins/code-suite/skills/orchestrator/references/routes.md))
   plus the risk overlay: low → plan; medium → spec + plan; high → spec + plan + ADRs + security review.
5. **Delegate** — each task goes to a subagent in a short brief; the orchestrator commits.
   See the [capability registry](plugins/code-suite/skills/orchestrator/references/capabilities.md).
6. **Validate and gate** — tests, code review, diff review and secret scan on the same
   commit, each recorded with `cs-evidence`; `cs-evidence verify` must pass before the
   work is called done.

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
| `design` | `design` | skill | Records a lasting architectural choice as an ADR before it is implemented |
| `implement` | `implementer` | subagent | Executes one scoped task with its tests; parallel when files are disjoint |
| `test` | `test` + `tester` | skill + subagent | Maps each acceptance criterion to tests that are proven to fail; reports bugs found instead of fixing them |
| `debug` | `debug` | skill | Reproduce → evidence → root cause → fix |
| `review` | `code-reviewer` + `review` | subagent + skill | Independent read-only review against goal/spec: verdict, findings by severity, acceptance-criteria coverage, credential checklist for auth code |
| `diff-review` | `diff-reviewer` + `diff-review` | subagent + skill | Hygiene pass on the final diff before a PR: scope, debug leftovers, env files, churn, disabled tests |
| `verify` | `verifier` | subagent | Runs tests, lint, type-check and build; honest pass/fail report |
| `spec-sync` | `spec-sync` | skill | Aligns the spec and existing docs with what was built; reports unexplained deviations instead of hiding them |
| `deliver` | `deliver` | skill | Clean diff and summary; commit / PR only when you ask |

Every skill can also be invoked directly, e.g. `/code-suite:debug the checkout test is flaky`.

## Repository structure

| Path | What it holds |
| --- | --- |
| `.claude-plugin/marketplace.json` | Marketplace manifest |
| `.github/workflows/validate.yml` | CI: manifests, frontmatter, shell syntax, JSON |
| `plugins/code-suite/.claude-plugin/plugin.json` | Plugin manifest |
| `plugins/code-suite/skills/orchestrator/` | Entry point: `SKILL.md`, `references/routes.md` (playbooks), `references/capabilities.md` (capability → component) |
| `plugins/code-suite/skills/code/` | `/code`: the orchestrator's flow in one command |
| `plugins/code-suite/skills/` | `spec`, `plan`, `design`, `test`, `debug`, `review`, `diff-review`, `spec-sync`, `deliver` |
| `plugins/code-suite/agents/` | Subagents: `code-explorer`, `implementer`, `tester`, `code-reviewer`, `diff-reviewer`, `verifier` |
| `plugins/code-suite/bin/` | `cs-context`, `cs-evidence`, `cs-secret-scan` (bash + git only) |
| `plugins/code-suite/scripts/guard-commit.sh` | Hook script: blocks `git commit` / `git push` with secrets |
| `plugins/code-suite/hooks/hooks.json` | Registers the hook (PreToolUse on Bash) |

## Validate locally

The same checks CI runs:

```bash
claude plugin validate --strict .
claude plugin validate --strict plugins/code-suite
for f in plugins/code-suite/bin/* plugins/code-suite/scripts/*.sh; do bash -n "$f"; done
for f in .claude-plugin/marketplace.json plugins/code-suite/.claude-plugin/plugin.json plugins/code-suite/hooks/hooks.json; do jq empty "$f"; done
```

To try local changes, add the clone as a marketplace:
`claude plugin marketplace add ./path/to/clone`.

## License

[MIT](LICENSE)
